--[[
    Copyright (C) 2019 Pau Escrich

    This program is free software; you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation; either version 2 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License along
    with this program; if not, write to the Free Software Foundation, Inc.,
    51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.

    The full GNU General Public License is included in this distribution in
    the file called "COPYING".
--]]

require("luci.sys")
local fs = require "nixio.fs"
local mdns = Map("bmx7-mdns", "mDNS")

local domains = mdns:section(NamedSection, "domains", "domains", translate("Mesh Domains"))
domains.addremove = false

local publish_hostname = domains:option(Flag,"publish_hostname",translate("Publish hostname"),
  translate("Automatically publish own hostname as domain name in the mesh network"))
publish_hostname.disabled = "0"
publish_hostname.enabled = "1"
publish_hostname.rmempty = false

local domains4 = domains:option(DynamicList,"domain4",translate("IPv4 TLD"),
  translate("IPv4 top level domains managed by mDNS. Other TLDs will be ignored"))

local domains6 = domains:option(DynamicList,"domain6",translate("IPv6 TLD"),
  translate("IPv6 top level domains managed by mDNS. Other TLDs will be ignored"))

local hosts = domains:option(DynamicList,"host",translate("Own domains"),
  translate([[Domains and hosts to publish in the mesh network.
<br>Syntax <b>domain.tld@ip</b> will announce domain attached to specified ip
<br>Syntax <b>domain.tld</b> (without ip) own node ip will be automatically announed for the domain]]))

local mdns_hosts = fs.readfile("/tmp/mdns.hosts") or ""
local mdns_hosts_text = [[
<div class="cbi-section-node">
  <div class="table" id="mdns_hosts_div">
   <div class="tr table-titles">
    <div class="th">Host</div>
    <div class="th">Announced domains</div>
   </div>
]]
for s in mdns_hosts:gmatch("[^\r\n]+") do
    local first=1
    local line=""
    for word in s:gmatch("%S+") do
        if first == 1 then
            first = 0
            line = '<div class="tr">\n<div class="td">'..word..'</div>\n<div class="td">\n'
        else
            line = line..'<a target="_blank" href="http://'..word..'">'..word..'</a>\n'
        end
    end
    mdns_hosts_text=mdns_hosts_text..line.."</div>\n</div>\n"
end
mdns_hosts_text=mdns_hosts_text..'</div></div>\n'

h = domains:option(DummyValue, "hosts", translate("mDNS global status"))
h.rawhtml = true
h.default = mdns_hosts_text
h.rmempty = false

function mdns.on_commit(self,map)
    luci.sys.call('/etc/init.d/bmx7-mdns reload')
end

return mdns
