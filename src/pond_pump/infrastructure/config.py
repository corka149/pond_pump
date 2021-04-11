"""
Config module that tries to fetch the matching config for given profile
 from PROJECT_PATH/config.
 """
import base64
import logging
import os
import pprint
from pathlib import Path
from typing import Dict, Any

import yaml
from gpiozero import InputDevice, Device
from gpiozero.pins.mock import MockFactory

_CONFIG_YAML: Dict[str, Any]
_LOG = logging.getLogger(__name__)


def init(profile: str):
    """ Init config file from path. """
    global _CONFIG_YAML

    config_path = os.path.abspath(os.path.dirname(__file__))
    config_path = os.path.join(
        config_path,
        f'../configuration/pond_pump-{profile.lower().strip()}.yaml')
    yaml_path = Path(config_path)
    if yaml_path.exists():
        with yaml_path.open('r') as yaml_file:
            _CONFIG_YAML = yaml.load(yaml_file, Loader=yaml.Loader)
    else:
        _CONFIG_YAML = dict()
        _LOG.debug('No "%s" found.', config_path)


def get_config(name: str):
    """
    Checks first the environment variable for a config.
    When it is not available it will look for it in the
    config file. It can only fetch simple types (int,
    str, float) or a list of str from an environment variable.
    The list must be colon separated.

    Example for config name: "database.authentication_source" is equal to

    in config file
    '''
    database:
        authentication_source: admin
    '''

    OR

    environment variable (watch out "_" becomes "__" and gets the "IOT_" prefix)
    '''
    IOT_DATABASE_AUTHENTICATION__SOURCE
    '''

    """
    # 1. Check environment variables
    env_name = name.replace('_', '__').replace('.', '_').upper()
    env_val = os.getenv('IOT_' + env_name)
    if env_val:
        if ';' in env_val:
            return [v.strip() for v in env_val.split(';')]
        return env_val

    # 2. Check config file
    keys = name.split('.')
    val = _CONFIG_YAML
    for k in keys:
        if isinstance(val, dict):
            val = val.get(k, {})

    if val:
        return val

    msg = f'"{name}" not found'
    _LOG.error(msg)
    _LOG.info('Has configs: %s', pprint.pformat(_CONFIG_YAML))
    raise ValueError(msg)


def build_device_url() -> str:
    """ Create url for responsible device """
    url = get_config('iot_server.address')
    device_name = get_config('device.name')
    return url + f'/device/{device_name}'


def basic_auth() -> Dict[str, str]:
    """ Creates the auth header """
    username = get_config('security.basic.username')
    passwd = get_config('security.basic.password')
    b64 = base64.b64encode(bytes(f'{username}:{passwd}', 'ascii'))
    return {'Authorization': f'Basic {b64.decode("ascii")}'}


def build_power_detector() -> InputDevice:
    """ Creates a device for detecting power activity """
    is_dev = get_config('dev_mode')

    if is_dev:
        Device.pin_factory = MockFactory()

    power_pin = get_config('device.power_pin')
    return InputDevice(power_pin)
