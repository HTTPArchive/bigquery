import subprocess
import setuptools

from setuptools.command.bdist_egg import bdist_egg as _bdist_egg

class bdist_egg(_bdist_egg):  # pylint: disable=invalid-name
  def run(self):
    self.run_command('CustomCommands')
    _bdist_egg.run(self)

# Some custom command to run during setup.
CUSTOM_COMMANDS = [
  ['apt-get', 'update'],
  ['apt-get', '--assume-yes', 'install', 'libre2-1', 'libre2-dev'],
]

class CustomCommands(setuptools.Command):
  def initialize_options(self):
    pass

  def finalize_options(self):
    pass

  def RunCustomCommand(self, command_list):
    print 'Running command: %s' % command_list
    p = subprocess.Popen(
        command_list,
        stdin=subprocess.PIPE, stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
    # Can use communicate(input='y\n'.encode()) if the command run requires
    # some confirmation.
    stdout_data, _ = p.communicate()
    print 'Command output: %s' % stdout_data
    if p.returncode != 0:
      raise RuntimeError(
          'Command %s failed: exit code: %s' % (command_list, p.returncode))

  def run(self):
    for command in CUSTOM_COMMANDS:
      self.RunCustomCommand(command)


# Configure the required packages and scripts to install.
REQUIRED_PACKAGES = [
  'adblockparser',
  're2'
]

setuptools.setup(
    name='adblock',
    version='0.0.1',
    description='adblock pipeline',
    install_requires=REQUIRED_PACKAGES,
    packages=setuptools.find_packages(),
    cmdclass={
        # Command class instantiated and run during easy_install scenarios.
        'bdist_egg': bdist_egg,
        'CustomCommands': CustomCommands,
        }
    )
