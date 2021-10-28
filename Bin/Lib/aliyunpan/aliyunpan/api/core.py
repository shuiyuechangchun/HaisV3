import sys
import time
from collections.abc import Iterable
from datetime import datetime
from pathlib import Path
from threading import RLock

import requests

from aliyunpan.api.req import *
from aliyunpan.api.type import UserInfo
from aliyunpan.api.utils import *
from aliyunpan.common import *
from aliyunpan.exceptions import InvalidRefreshToken, AliyunpanException, AliyunpanCode, LoginFailed, \
    InvalidContentHash, UploadUrlExpired, UploadUrlFailedRefresh, PartNumberOverLimit, BadResponseCode, \
    PartNotSequential, InvalidExpiration

__all__ = ['AliyunPan']


class AliyunPan(object):

    def __init__(self, refresh_token: str = None):
        self._req = Req(self)
        self._user_info = None
        self._access_token = None
        self._drive_id = None
        self._username = None
        self._password = None
        self._refresh_token = refresh_token
        self._access_token_gen_ = self._access_token_gen()
        self._drive_id_gen_ = self._drive_id_gen()
        self._chunk_size = 524288
        self._print = Printer()
        self._lock = RLock()

    refresh_token = property(lambda self: self._refresh_token,
                             lambda self, value: setattr(self, '_refresh_token', value))
    access_token = property(lambda self: (self._lock.acquire(), next(self._access_token_gen_), self._lock.release())[1],
                            lambda self, value: setattr(self, '_access_token', value))
    drive_id = property(lambda self: (self._lock.acquire(), next(self._drive_id_gen_), self._lock.release())[1],
                        lambda self, value: setattr(self, '_drive_id', value))

    def login(self, username: str = None, password: str = None):
        """
        登录api
        https://github.com/zhjc1124/aliyundrive
        :param username:
        :param password:
        :return:
        """
        if username:
            self._username = username
        else:
            username = self._username
        if password:
            self._password = password
        else:
            password = self._password
        if not username and not password:
            raise LoginFailed
        password2 = encrypt(password)
        LOGIN = {
            'method': 'POST',
            'url': 'https://passport.aliyundrive.com/newlogin/login.do',
            'data': {
                'loginId': username,
                'password2': password2,
                'appName': 'aliyun_drive',
            }
        }
        logger.info('Logging in.')
        r = self._req.req(**LOGIN, access_token=False)
        logger.debug(r.json())
        try:
            data = parse_biz_ext(r.json()['content']['data']['bizExt'])
            logger.debug(data)
            access_token = data['pds_login_result']['accessToken']
            self._access_token = access_token
            GLOBAL_VAR.access_token = access_token
            refresh_token = data['pds_login_result']['refreshToken']
            self._refresh_token = refresh_token
            GLOBAL_VAR.refresh_token = refresh_token
            drive_id = data['pds_login_result']['defaultDriveId']
            self._drive_id = drive_id
            GLOBAL_VAR.drive_id = drive_id
            return self._refresh_token
        except KeyError:
            pass
        raise LoginFailed

    def get_file_list(self, parent_file_id: str = 'root', next_marker: str = None) -> list:
        """
        获取文件列表
        :param parent_file_id:
        :param next_marker:
        :return:
        """
        url = 'https://api.aliyundrive.com/v2/file/list'
        json = {"drive_id": self.drive_id, "parent_file_id": parent_file_id, 'fields': '*', 'marker': next_marker}
        logger.info(f'Get the list of parent_file_id {parent_file_id}.')
        r = self._req.post(url, json=json)
        logger.debug(r.json())
        if 'items' not in r.json():
            return []
        file_list = r.json()['items']
        if 'next_marker' in r.json() and r.json()['next_marker'] and next_marker != r.json()['next_marker']:
            file_list.extend(self.get_file_list(parent_file_id, r.json()['next_marker']))
        return file_list

    def delete_file(self, file_id: str):
        """
        删除文件
        :param file_id:
        :return:
        """
        url = 'https://api.aliyundrive.com/v2/batch'
        json = {'requests': [{'body': {'drive_id': self.drive_id, 'file_id': file_id},
                              'headers': {'Content-Type': 'application/json'},
                              'id': file_id, 'method': 'POST',
                              'url': '/recyclebin/trash'}], 'resource': 'file'}
        logger.info(f'Delete file {file_id}.')
        r = self._req.post(url, json=json)
        logger.debug(r.text)
        if r.status_code == 200:
            return r.json()['responses'][0]['id']
        return False

    def move_file(self, file_id: str, parent_file_id: str):
        """
        移动文件
        :param file_id:
        :param parent_file_id:
        :return:
        """
        url = 'https://api.aliyundrive.com/v2/batch'
        json = {"requests": [{"body": {"drive_id": self.drive_id, "file_id": file_id,
                                       "to_parent_file_id": parent_file_id},
                              "headers": {"Content-Type": "application/json"},
                              "id": file_id, "method": "POST", "url": "/file/move"}],
                "resource": "file"}
        logger.info(f'Move files {file_id} to {parent_file_id}')
        r = self._req.post(url, json=json)
        if r.status_code == 200:
            if 'message' in r.json()['responses'][0]['body']:
                print(r.json()['responses'][0]['body']['message'])
                return False
            return r.json()['responses'][0]['id']
        return False

    def update_file(self, file_id: str, name: str):
        """
        重命名文件
        :param file_id:
        :param name:
        :return:
        """
        url = 'https://api.aliyundrive.com/v2/file/update'
        json = {"drive_id": self.drive_id, "file_id": file_id, "name": name,
                "check_name_mode": "refuse"}
        r = self._req.post(url, json=json)
        logger.info(f'Rename {file_id} to {name}')
        logger.debug(r.json())
        if r.status_code == 200:
            return r.json()['file_id']
        return r.json()['code']

    def get_user_info(self) -> UserInfo:
        """
        获取用户信息
        :return:
        """
        url = 'https://api.aliyundrive.com/v2/user/get'
        logger.info('Get user information.')
        r = self._req.post(url, json={})
        user_info = r.json()
        id_ = user_info['user_id']
        nick_name = user_info['nick_name']
        ctime = user_info['created_at']
        phone = user_info['phone']
        drive_id = user_info['default_drive_id']
        user_info = UserInfo(id=id_, nick_name=nick_name, ctime=ctime, phone=phone, drive_id=drive_id)
        logger.debug(user_info)
        self._user_info = user_info
        GLOBAL_VAR.user_info = user_info
        return user_info

    def create_file(self, file_name: str, parent_file_id: str = 'root', file_type: bool = False,
                    json: dict = None, force: bool = False) -> requests.models.Response:
        """
        创建文件
        :param file_name:
        :param parent_file_id:
        :param file_type:
        :param json:
        :param force:
        :return:
        """
        j = {
            "name": file_name,
            "drive_id": self.drive_id,
            "parent_file_id": parent_file_id,
            "content_hash_name": "sha1",
        }
        if file_type:
            f_type = 'file'
            check_name_mode = 'auto_rename'
            if force:
                check_name_mode = 'refuse'
        else:
            f_type = 'folder'
            check_name_mode = 'refuse'
        j.update({"type": f_type, 'check_name_mode': check_name_mode})
        if json:
            j.update(json)
        # 申请创建文件
        url = 'https://api.aliyundrive.com/v2/file/create'
        logger.info(f'Create file {file_name} in file {parent_file_id}.')
        retry_num = 3
        while retry_num:
            try:
                r = self._req.post(url, json=j)
            except requests.exceptions.RequestException:
                logger.error(sys.exc_info())
                retry_num -= 1
            else:
                break
        else:
            raise requests.exceptions.RequestException
        logger.debug(j)
        if force and 'exist' in r.json():
            self.delete_file(r.json()['file_id'])
            return self.create_file(file_name, parent_file_id, file_type, json)
        return r

    def upload_file(self, parent_file_id: str = 'root', path: str = None, upload_timeout: float = 10,
                    retry_num: int = 3, force: bool = False, chunk_size: int = None, c: bool = False):
        """
        上传文件
        :param parent_file_id: 上传目录的id
        :param path: 上传文件路径
        :param upload_timeout: 分块上传超时时间
        :param retry_num:
        :param force: 强制覆盖
        :param chunk_size: 分块大小
        :param c: 断点续传
        :return:
        """
        path = Path(path)
        file_size = path.stat().st_size
        file_name = path.name
        self._chunk_size = chunk_size or self._chunk_size
        # 获取sha1
        content_hash = get_sha1(path, self._chunk_size)
        while True:
            # 分片列表
            part_info_list = []
            count = int(file_size / self._chunk_size) + 1
            for i in range(count):
                part_info_list.append({"part_number": i + 1})
            if len(part_info_list) > 10000:
                if chunk_size:
                    raise PartNumberOverLimit
                self._chunk_size = int(file_size / 1000)
                continue
            break
        json = {"size": file_size, "part_info_list": part_info_list, "content_hash": content_hash}
        path_list = []
        existed = False
        # 已存在任务
        if content_hash in GLOBAL_VAR.tasks:
            # 是否是列表或可迭代对象
            if isinstance(GLOBAL_VAR.tasks[content_hash].path, Iterable) and not isinstance(
                    GLOBAL_VAR.tasks[content_hash].path, str):
                path_list.extend(GLOBAL_VAR.tasks[content_hash].path)
            else:
                path_list.append(GLOBAL_VAR.tasks[content_hash].path)
            path_list = list(set([str(Path(path_).absolute()) for path_ in path_list]))
            flag = False
            # 云盘是否存在该文件
            if GLOBAL_VAR.tasks[content_hash].upload_time and path_list:
                existed = True
                for path_ in path_list:
                    # 是否存在路径
                    if path.absolute() == Path(path_).absolute():
                        flag = True
                        break
            # 云盘存在该文件且存在路径且断点续传
            if existed and flag and c:
                # 已存在跳过上传
                self._print.upload_info(path, status=True, existed=True)
                self._print.print_line()
                GLOBAL_VAR.tasks[content_hash].path = path_list[0] if len(path_list) == 1 else path_list
                GLOBAL_VAR.file_set.add((content_hash, str(path.absolute())))
                return GLOBAL_VAR.tasks[content_hash].file_id
        # 断点续传且已存在任务且云盘不存在该文件
        if c and content_hash in GLOBAL_VAR.tasks and not existed:
            upload_id = GLOBAL_VAR.tasks[content_hash].upload_id
            file_id = GLOBAL_VAR.tasks[content_hash].file_id
            self._chunk_size = GLOBAL_VAR.tasks[content_hash].chunk_size
            part_number = GLOBAL_VAR.tasks[content_hash].part_number
            try:
                # 获取上传链接列表
                part_info_list = self.get_upload_url(path, upload_id, file_id, self._chunk_size, part_number)
                if not part_info_list:
                    # 重新上传
                    if str(path.absolute()) in path_list:
                        # 删除未上传成功的任务
                        del path_list[str(path.absolute())]
                    GLOBAL_VAR.tasks[content_hash].path = path_list[0] if len(path_list) == 1 else path_list
                    return self.upload_file(parent_file_id=parent_file_id, path=path, upload_timeout=upload_timeout,
                                            retry_num=retry_num, force=force, chunk_size=self._chunk_size, c=c)
            except FileExistsError:
                # 漏网之鱼
                self._print.upload_info(path, status=True, existed=True)
                self._print.print_line()
                path_list.append(str(path.absolute()))
                path_list = list(set(path_list))
                GLOBAL_VAR.tasks[content_hash].path = path_list[0] if len(path_list) == 1 else path_list
                GLOBAL_VAR.file_set.add((content_hash, str(path.absolute())))
                return GLOBAL_VAR.tasks[content_hash].file_id
        else:
            # 申请创建文件
            r = self.create_file(file_name=file_name, parent_file_id=parent_file_id, file_type=True, json=json,
                                 force=force)
            if 'rapid_upload' not in r.json():
                message = r.json()['message']
                logger.error(message)
                raise AliyunpanException(message)
            task_info = {'path': str(path.absolute()), 'upload_id': None,
                         'file_id': None, 'chunk_size': self._chunk_size,
                         'part_number': None}
            rapid_upload = r.json()['rapid_upload']
            # 快速上传成功
            if rapid_upload:
                self._print.upload_info(path, status=True, rapid_upload=True)
                self._print.print_line()
                file_id = r.json()['file_id']
                task_info['file_id'] = file_id
                task_info['upload_time'] = time.time()
                GLOBAL_VAR.tasks[content_hash] = task_info
                GLOBAL_VAR.file_set.add((content_hash, str(path.absolute())))
                if existed:
                    # 同hash不同路径
                    path_list.append(str(path.absolute()))
                    path_list = list(set(path_list))
                    GLOBAL_VAR.tasks[content_hash].path = path_list[0] if len(path_list) == 1 else path_list
                return file_id
            else:
                upload_id = r.json()['upload_id']
                file_id = r.json()['file_id']
                part_info_list = r.json()['part_info_list']
                task_info['upload_id'] = upload_id
                task_info['file_id'] = file_id
                task_info['part_number'] = 1
                GLOBAL_VAR.tasks[content_hash] = task_info
        upload_bar = UploadBar(size=file_size)
        upload_bar.upload_info(path)
        upload_bar.print_line()
        upload_bar.update(refresh_line=False)
        logger.debug(f'upload_id: {upload_id}, file_id: {file_id}, part_info_list: {part_info_list}')
        part_info_list = Iter(part_info_list)
        for i in part_info_list:
            part_number, upload_url = i['part_number'], i['upload_url']
            if not upload_url:
                continue
            GLOBAL_VAR.tasks[content_hash].part_number = part_number
            # 分块读取
            with path.open('rb') as f:
                f.seek((part_number - 1) * self._chunk_size)
                chunk = f.read(self._chunk_size)
            if not chunk:
                break
            size = len(chunk)
            retry_count = 0
            while True:
                upload_bar.update(refresh_line=True)
                logger.debug(
                    f'(upload_id={upload_id}, file_id={file_id}, size={size}): Upload part of {part_number} to {upload_url}.')
                try:
                    # 开始上传
                    r = self._req.put(upload_url, data=chunk, timeout=upload_timeout, access_token=False)
                    if r.status_code == AliyunpanCode.request_expired:
                        raise UploadUrlExpired
                    elif r.status_code == AliyunpanCode.part_already_exist:
                        pass
                    elif r.status_code == AliyunpanCode.part_not_sequential:
                        raise PartNotSequential
                    elif r.status_code != 200:
                        logger.error(r.status_code)
                        raise BadResponseCode
                    break
                except (requests.exceptions.SSLError, requests.exceptions.ConnectionError,
                        requests.exceptions.ReadTimeout):
                    logger.warn('Upload timeout.')
                    if retry_count is retry_num:
                        self._print.error_info(f'上传超时{retry_num}次，即将重新上传', refresh_line=True)
                        time.sleep(1)
                        return self.upload_file(parent_file_id=parent_file_id, path=path, upload_timeout=upload_timeout,
                                                retry_num=retry_num, force=force, chunk_size=self._chunk_size, c=c)
                    self._print.error_info('上传超时', refresh_line=True)
                    retry_count += 1
                    time.sleep(1)
                except KeyboardInterrupt:
                    raise
                except UploadUrlExpired:
                    info = f'Part {part_number} upload request has expired.'
                    logger.warning(info)
                    self._print.error_info(info, refresh_line=True)
                    time.sleep(1)
                    part_info_list_ = self.get_upload_url(path=path, upload_id=upload_id, file_id=file_id,
                                                          chunk_size=self._chunk_size)
                    if part_info_list_:
                        part_info_list.iter = part_info_list_
                        part_info = [i for i in part_info_list if i['part_number'] == part_number][0]
                        upload_url = part_info['upload_url']
                        logger.info(f'The upload_url of Part {part_number} has been refreshed.')
                        logger.debug(upload_url)
                    else:
                        logger.error(f'The upload_url of Part {part_number} failed to refresh.')
                        raise UploadUrlFailedRefresh
                except (BadResponseCode, PartNotSequential):
                    raise
                except:
                    logger.error(sys.exc_info())
                    exc_type, exc_value, exc_traceback = sys.exc_info()
                    self._print.error_info(exc_type.__name__, refresh_line=True)
                    time.sleep(1)
                self._print.wait_info(refresh_line=True)
            k = part_number / len(part_info_list)
            upload_bar.update(ratio=k, refresh_line=True)
        file_info = None
        try:
            file_info = self.complete(file_id, upload_id)
        except InvalidContentHash:
            upload_bar.upload_info(path, status=False, refresh_line=True)
            if Path(log_file).absolute() != path.absolute():
                raise
        if file_info:
            upload_bar.upload_info(path, status=True, t=upload_bar.time, average_speed=upload_bar.average_speed,
                                   refresh_line=True)
            self._print.print_line()
            GLOBAL_VAR.tasks[content_hash].upload_time = time.time()
            GLOBAL_VAR.file_set.add((content_hash, str(path.absolute())))
            return file_info
        else:
            upload_bar.upload_info(path, status=False, refresh_line=True)
            self._print.print_line()
            return False

    def complete(self, file_id, upload_id):
        """
        上传成功保存文件
        """
        url = 'https://api.aliyundrive.com/v2/file/complete'
        json = {
            "ignoreError": True,
            "drive_id": self.drive_id,
            "file_id": file_id,
            "upload_id": upload_id
        }
        r = self._req.post(url, json=json)
        logger.debug(r.json())
        if 'code' in r.json() and r.json()['code'] == AliyunpanCode.invalid_content_hash:
            raise InvalidContentHash
        if r.status_code == 200:
            return r.json()
        return False

    def get_upload_url(self, path: str, upload_id: str, file_id: str, chunk_size: int, part_number: int = 1) -> list:
        """
        获取上传地址
        :param path:
        :param upload_id:
        :param file_id:
        :param chunk_size:
        :param part_number:
        :return:
        """
        url = 'https://api.aliyundrive.com/v2/file/get_upload_url'
        path = Path(path)
        file_size = path.stat().st_size
        part_info_list = []
        count = int(file_size / chunk_size) + 1
        for i in range(count):
            part_info_list.append({"part_number": i + 1})
        json = {
            "drive_id": self.drive_id,
            "file_id": file_id,
            "part_info_list": part_info_list,
            "upload_id": upload_id,
        }
        r = self._req.post(url, json=json)
        if 'code' in r.json() and r.json()['code'] == AliyunpanCode.existed:
            raise FileExistsError
        part_info_list = r.json()['part_info_list']
        for i in part_info_list[:part_number - 1]:
            i['upload_url'] = ''
        return part_info_list

    def get_access_token(self) -> str:
        """
        获取access_token
        :return:
        """
        # url = 'https://websv.aliyundrive.com/token/refresh'
        # json = {"refresh_token": self.refresh_token}
        url = 'https://auth.aliyundrive.com/v2/account/token'
        json = {"refresh_token": self.refresh_token, 'grant_type': 'refresh_token'}
        logger.info(f'Get ACCESS_TOKEN.')
        r = self._req.post(url, json=json, access_token=False)
        try:
            access_token = r.json()['access_token']
        except KeyError:
            raise InvalidRefreshToken
        GLOBAL_VAR.refresh_token = self.refresh_token
        GLOBAL_VAR.access_token = access_token
        logger.debug(access_token)
        return access_token

    def _access_token_gen(self) -> str:
        """
        access_token生成器
        :return:
        """
        access_token = None
        while True:
            if self._access_token:
                yield self._access_token
            elif access_token:
                yield access_token
            else:
                access_token = self.get_access_token()

    def get_drive_id(self) -> str:
        """
        获取drive_id
        :return:
        """
        drive_id = self.get_user_info().drive_id
        self._drive_id = drive_id
        GLOBAL_VAR.drive_id = drive_id
        return drive_id

    def _drive_id_gen(self) -> str:
        """
        drive_id生成器
        :return:
        """
        drive_id = None
        while True:
            if self._drive_id:
                yield self._drive_id
            elif drive_id:
                yield drive_id
            else:
                drive_id = self.get_drive_id()

    def get_download_url(self, file_id, expire_sec=14400, category=None) -> str:
        """
        获取分享链接
        :param file_id:
        :param expire_sec: 文件过期时间（秒）
        :param category:
        :return:
        """
        url = 'https://api.aliyundrive.com/v2/file/get_download_url'
        illegal_url = 'https://pds-system-file.oss-cn-beijing.aliyuncs.com/illegal.mp4'
        json = {'drive_id': self.drive_id, 'file_id': file_id, 'expire_sec': expire_sec}
        logger.info(f'Get file {file_id} download link, expiration time {expire_sec} seconds.')
        r = self._req.post(url, json=json)
        url = r.json()['url'] if 'url' in r.json() else ''
        if not url or url == illegal_url:
            url_dict = self.get_play_info(file_id, expire_sec, category) if category else \
                self.get_play_info(file_id, expire_sec, 'video') or self.get_play_info(file_id, expire_sec, 'audio')
            if url_dict:
                url = list(url_dict.values())[-1]
            elif 'internal_url' in r.json() and r.json()['internal_url']:
                url = r.json()['internal_url']
        logger.debug(f'file_id:{file_id},expire_sec:{expire_sec},url:{url}')
        return url

    def save_share_link(self, name: str, content_hash: str, content_hash_name: str, size: str,
                        parent_file_id: str = 'root', force: bool = False) -> bool:
        """
        保存分享文件
        :param content_hash_name:
        :param name:
        :param content_hash:
        :param size:
        :param parent_file_id:
        :param force:
        :return:
        """
        logger.info(f'name: {name}, content_hash:{content_hash}, size:{size}')
        json = {'content_hash': content_hash, 'size': int(size), 'content_hash_name': content_hash_name or 'sha1'}
        r = self.create_file(name, parent_file_id=parent_file_id, file_type=True, json=json, force=force)
        if r.status_code == 201 and 'rapid_upload' in r.json() and r.json()['rapid_upload']:
            return r.json()['file_id']
        elif 'message' in r.json():
            logger.debug(r.json())
            print(r.json()["message"])
        return False

    def search(self, query: str, next_marker: str = None):
        """
        搜索文件
        :param query
        :param next_marker
        """
        url = 'https://api.aliyundrive.com/v2/file/search'
        json = {
            'drive_id': self.drive_id,
            'query': f'name match \"{query}\"',
            'order_by': 'updated_at DESC'
        }
        r = self._req.post(url, json=json)
        if 'items' not in r.json():
            return []
        file_list = r.json()['items']
        if 'next_marker' in r.json() and r.json()['next_marker'] and next_marker != r.json()['next_marker']:
            file_list.extend(self.search(query, r.json()['next_marker']))
        return file_list

    def get_play_info(self, file_id, expire_sec=14400, category=None):
        url = 'https://api.aliyundrive.com/v2/databox/get_{}_play_info'
        if category:
            url = url.format(category)
        else:
            return {}
        j = {'drive_id': self.drive_id, 'file_id': file_id, 'expire_sec': expire_sec}
        r = self._req.post(url, json=j)
        if r.status_code != 200:
            return {}
        if 'code' in r.json() and r.json()['code'] == AliyunpanCode.not_found_file:
            return {}
        play_dict = {}
        if 'template_list' in r.json():
            for i in r.json()['template_list']:
                if i['status']:
                    try:
                        play_dict[i['template_id']] = i['url']
                    except KeyError:
                        pass
            return play_dict
        return {}

    def share_link(self, file_id_list: list, expiration=''):
        url = 'https://api.aliyundrive.com/adrive/v2/share_link/create'
        if expiration:
            expiration = datetime.fromtimestamp(float(expiration) + time.timezone) \
                             .strftime('%Y-%m-%dT%H:%M:%S.%f')[:-3] + 'Z'
        j = {'drive_id': self.drive_id, 'file_id_list': file_id_list, 'expiration': expiration}
        r = self._req.post(url, json=j)
        if 'code' in r.json():
            if r.json()['code'] == AliyunpanCode.Forbidden:
                return ''
            elif r.json()['code'] == AliyunpanCode.InvalidExpiration:
                raise InvalidExpiration
            else:
                return ''
        return r.json()['share_url']
