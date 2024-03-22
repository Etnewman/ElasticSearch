# OADCGS ES Developer Guide

# Requirements

The following software is required and the instructions below will walk you
through how to install and configure each of them.

- [Git]
- [Python]
- [Ruby]
- [VirtualEnv]
- [pyenv]
- [pyenv-win]
- [rbenv]
- [rbenv-win]

# 1. Installation

## 1.1. Install Python

The [Python] programming language is for linting via the `pre-commit` [Python]
package. Most of the ES DevOps development uses [Python].

### 1.1.1. Install Python on macOS

While [Python] is available on most systems, we manage [Python] using the
[pyenv] tool.

[pyenv] is a tool to manage multiple versions of [Python] in a users home
directory. This allows you to have independent versions of [Python] so that you
don't have to modify the system installation of [Python].

```bash
brew install pyenv
echo 'eval "$(pyenv init -)"' >> ~/.bashrc
source ~/.bashrc
pyenv install 3.7.5
pyenv global 3.7.5
```

### 1.1.2. Install Python on Windows

```powershell
git clone https://github.com/pyenv-win/pyenv-win.git $HOME\.pyenv
```

## 1.2. Install Virtualenv

[Virtualenv] is a tool which creates a per project installation of [Python].
This way, we can manage a specific version of [Python] and the [Python] packages
for the project.

```
pip install virtualenv
```

## 1.3. Initialize virtualenv

```
virtualenv .venv
```

## 1.4. Activate the virtualenv environment

### 1.4.1. Activate on Windows

```
.\.venv\Scripts\activate
```

### 1.4.2. Activate on macOS and Linux

```bash
source .venv/bin/activate
```

## 1.5. Install Python packages

```
pip install -r requirements.txt
```

## 1.6. Install Ruby

The [Ruby] programming language is used for linting the `Vagrantfile` and for
Puppet module development.

### 1.6.1. Install Ruby For macOS

```bash
brew install rbenv
echo 'eval "$(rbenv init -)"' >> ~/.bashrc
source ~/.bashrc
rbenv install 2.6.0
rbenv global 2.6.0
rbenv rehash
gem install bundle
```

### 1.6.2. Install Ruby For Windows

Installation on Windows uses [rbenv-win] to manage the Ruby.

#### 1.6.2.1. Clone rbenv-win repository

Open PowerShell and clone the git repository

```powershell
git clone https://github.com/nak1114/rbenv-win.git $HOME\.rbenv-win
```

##### 1.6.2.2. Update PATH

Add the `bin` and `shims` directory to your PATH environment variable for access
to the `rbenv` command.

```powershell
$oldpath=(Get-ItemProperty -Path "HKCU:\Environment" -Name PATH -EA SilentlyContinue).path

$newpath="$HOME\.rbenv-win\bin;$HOME\.rbenv-win\shims;$oldpath"

Set-ItemProperty -Path "HKCU:\Environment" -Name PATH -Value $newpath
```

##### 1.6.2.3. Restart Powershell

Close the `powershell` window then open a new window. This will reload your
PATH.

##### 1.6.2.4. Initialize rbenv

Run the following command after `rbenv` installation to enable `ruby`

```powershell
rbenv install 2.6.0
rbenv global 2.6.0
rbenv rehash
gem install bundle
```

## 1.7. Do awesome stuff

[python]: https://www.python.org/downloads/
[ruby]: https://www.ruby-lang.org/en/
[virtualenv]: https://virtualenv.pypa.io/en/stable/
[rbenv-win]: https://github.com/nak1114/rbenv-win
[rbenv]: https://github.com/rbenv/rbenv
[pyenv]: https://github.com/pyenv/pyenv
[pyenv-win]: https://github.com/pyenv-win/pyenv-win
[git]: https://git-scm.com
