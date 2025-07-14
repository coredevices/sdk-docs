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

{% if include.mac %}
1. If you have not already, download the [latest version of the SDK]({{ site.links.pebble_tool_root }}pebble-sdk-{{ site.data.sdk.pebble_tool.version }}-mac.tar.bz2).
{% else %}
1. If you have not already, download the latest version of the SDK - 
   [Linux 32-bit]({{ site.links.pebble_tool_root }}pebble-sdk-{{ site.data.sdk.pebble_tool.version }}-linux32.tar.bz2) |
   [Linux 64-bit]({{ site.links.pebble_tool_root }}pebble-sdk-{{ site.data.sdk.pebble_tool.version }}-linux64.tar.bz2).
{% endif %}

2. Open {% if include.mac %}Terminal{% else %}a terminal{% endif %} window and
  create a directory to host all Pebble tools:

    ```bash
    mkdir {{ site.data.sdk.path }}
    ```

3. Change into that directory and extract the Pebble SDK that you just
  downloaded, for example:

    ```bash
    cd {{ site.data.sdk.path }}
    tar -jxf ~/Downloads/pebble-sdk-{{ site.data.sdk.pebble_tool.version }}-{% if include.mac %}mac{% else %}linux64{% endif %}.tar.bz2
    ```

    {% unless include.mac %}
    > Note: If you are using 32-bit Linux, the path shown above will be 
    > different as appropriate.
    {% endunless %}

    You should now have the directory
    `{{ site.data.sdk.path }}pebble-sdk-{{ site.data.sdk.pebble_tool.version }}-{% if include.mac %}mac{% else %}linux64{% endif %}` with the SDK files and directories inside it.

4. Add the `pebble` tool to your path and reload your shell configuration:

    ```bash
    echo 'export PATH=~/pebble-dev/pebble-sdk-{{ site.data.sdk.pebble_tool.version }}-{% if include.mac %}mac{% else %}linux64{% endif %}/bin:$PATH' >> ~/.bash_profile
    . ~/.bash_profile
    ```

You can now continue on and install the rest of the dependencies.
