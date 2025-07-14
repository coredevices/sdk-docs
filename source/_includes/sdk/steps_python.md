{% comment %}
 Copyright 2025 Google LLC

 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at

     http://www.apache.org/licenses/LICENSE-2.0

 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.
{% endcomment %}

### Download and install Python libraries

The Pebble SDK depends on Python libraries to convert fonts and images from your
computer into Pebble resources.

{% if include.mac %}
You need to use the standard Python `easy_install` package manager to install
the alternative `pip` package manager. This is then used to install other Python
dependencies.

Follow these steps in Terminal:
{% endif %}

1. Install `pip` and `virtualenv`:

    ```bash
    {% if include.mac %}sudo easy_install pip{% else %}sudo apt-get install python-pip python2.7-dev{% endif %}
    sudo pip install virtualenv
    ```

2. Install the Python library dependencies locally:

    ```bash
    cd {{ site.data.sdk.path }}pebble-sdk-{{ site.data.sdk.pebble_tool.version }}-{% if include.mac %}mac{% else %}linux64{% endif %}
    virtualenv --no-site-packages .env
    source .env/bin/activate
    {% if include.mac %}CFLAGS="" {% endif %}pip install -r requirements.txt
    deactivate
    ```

> **Note: virtualenv is not optional.**
