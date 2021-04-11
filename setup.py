from setuptools import setup

setup(
    name='pond_pump',
    version='1.0.4',
    packages=['pond_pump', 'pond_pump.model', 'pond_pump.infrastructure'],
    package_dir={'': 'src'},
    include_package_data=True,  # IMPORTANT for configs in combination with MANIFEST.in
    url='https://github.com/corka149/pond_pump',
    license='',
    author='corka',
    author_email='corka149@mailbox.org',
    description='Sends a message when the pond pump gets active.',
    install_requires=[
        'pydantic',
        'PyYAML',
        'aiohttp',
        'gpiozero',
        'RPi.GPIO'
    ]
)
