-- 配置 日志级别
{{ $LOG_LEVEL := .Env.LOG_LEVEL | default "info" }}

-- Prosody Example Configuration File
--
-- Information on configuring Prosody can be found on our
-- website at http://prosody.im/doc/configure
--
-- Tip: You can check that the syntax of this file is correct
-- when you have finished by running: luac -p prosody.cfg.lua
-- If there are any errors, it will let you know what and where
-- they are, otherwise it will keep quiet.
--
-- The only thing left to do is rename this file to remove the .dist ending, and fill in the
-- blanks. Good luck, and happy Jabbering!


---------- Server-wide settings ----------
-- Settings in this section apply to the whole server and are the default settings
-- for any virtual hosts

-- This is a (by default, empty) list of accounts that are admins
-- for the server. Note that you must create the accounts separately
-- (see http://prosody.im/doc/creating_accounts for info)
-- Example: admins = { "user1@example.com", "user2@example.net" }
admins = { }

-- Enable use of libevent for better performance under high load
-- For more information see: http://prosody.im/doc/libevent
--use_libevent = true;

-- This is the list of modules Prosody will load on startup.
-- It looks for mod_modulename.lua in the plugins folder, so make sure that exists too.
-- Documentation on modules can be found at: http://prosody.im/doc/modules
modules_enabled = {

	-- Generally required
		"roster"; -- Allow users to have a roster. Recommended ;)
		"saslauth"; -- Authentication for clients and servers. Recommended if you want to log in.
		"tls"; -- Add support for secure TLS on c2s/s2s connections
		"c"; -- s2s dialback support
		"disco"; -- Service discovery

	-- Not essential, but recommended
		"private"; -- Private XML storage (for room bookmarks, etc.)
		"vcard"; -- Allow users to set vCards
		-- 开启限速模块
		"limits"; -- Enable bandwidth limiting for XMPP connections

	-- These are commented by default as they have a performance impact
		--"privacy"; -- Support privacy lists
		--"compression"; -- Stream compression (Debian: requires lua-zlib module to work)

	-- Nice to have
		"version"; -- Replies to server version requests
		"uptime"; -- Report how long server has been running
		"time"; -- Let others know the time here on this server
		"ping"; -- Replies to XMPP pings with pongs
		"pep"; -- Enables users to publish their mood, activity, playing music and more
		"register"; -- Allow users to register on this server using a client and change passwords

	-- Admin interfaces
		"admin_adhoc"; -- Allows administration via an XMPP client that supports ad-hoc commands
		--"admin_telnet"; -- Opens telnet console interface on localhost port 5582

	-- HTTP modules
		--"bosh"; -- Enable BOSH clients, aka "Jabber over HTTP"
		--"http_files"; -- Serve static files from a directory over HTTP

	-- Other specific functionality
		"posix"; -- POSIX functionality, sends server to background, enables syslog, etc.
		--"groups"; -- Shared roster support
		--"announce"; -- Send announcement to all online users
		--"welcome"; -- Welcome users who register accounts
		--"watchregistrations"; -- Alert admins of registrations
		--"motd"; -- Send a message to users when they log in
		--"legacyauth"; -- Legacy authentication. Only used by some old clients and bots.
        {{ if .Env.GLOBAL_MODULES }}
        "{{ join "\";\n\"" (splitList "," .Env.GLOBAL_MODULES) }}";
        {{ end }}
};

https_ports = { } // 注释它 不再监听5082

-- These modules are auto-loaded, but should you want
-- to disable them then uncomment them here:
modules_disabled = {
	-- "offline"; -- Store offline messages
	-- "c2s"; -- Handle client connections
	"s2s"; -- Handle server-to-server connections
};

-- Disable account creation by default, for security
-- For more information see http://prosody.im/doc/creating_accounts
allow_registration = false;
-- 后台化 ...
daemonize = false;

-- Enable rate limits for incoming client and server connections
limits = {
  c2s = {
    rate = "10kb/s";
  };
  s2sin = {
    rate = "30kb/s";
  };
}

pidfile = "/config/data/prosody.pid";

-- Force clients to use encrypted connections? This option will
-- prevent clients from authenticating unless they are using encryption.
-- 客户端到服务端不需要加密
c2s_require_encryption = false

-- Force certificate authentication for server-to-server connections?
-- This provides ideal security, but requires servers you communicate
-- with to support encryption AND present valid, trusted certificates.
-- NOTE: Your version of LuaSec must support certificate verification!
-- For more information see http://prosody.im/doc/s2s#security
-- 服务端到服务端不需要加密
s2s_secure_auth = false

-- Many servers don't support encryption or have invalid or self-signed
-- certificates. You can list domains here that will not be required to
-- authenticate using certificates. They will be authenticated using DNS.
-- 指定某些域就是不安全的 ...(不需要认证)
--s2s_insecure_domains = { "gmail.com" }

-- Even if you leave s2s_secure_auth disabled, you can still require valid
-- certificates for some domains by specifying a list here.
-- 就算禁止了  你还是想要需要有效的证书进行认证
--s2s_secure_domains = { "jabber.org" }

-- Select the authentication backend to use. The 'internal' providers
-- use Prosody's configured data storage to store the authentication data.
-- To allow Prosody to offer secure authentication mechanisms to clients, the
-- default provider stores passwords in plaintext. If you do not trust your
-- server please see http://prosody.im/doc/modules/mod_auth_internal_hashed
-- for information about using the hashed backend.
-- 选择认证骨架 .. internal 提供者 使用Prosody的配置的数据存储存储这些认证数据 ...
-- 为了允许Prosody 提供安全的认证机制给客户端,默认的提供者  存储密码为简单文本.. 如果你不信任你的服务器
-- 请参考文档 - 了解hashed backend 信息
authentication = "internal_hashed"

-- Select the storage backend to use. By default Prosody uses flat files
-- in its configured data directory, but it also supports more backends
-- through modules. An "sql" backend is included by default, but requires
-- additional dependencies. See http://prosody.im/doc/storage for more info.
-- 选择存储后端
-- 默认Prosody 使用扁平化的文件 - 在它的默认配置数据目录下, 但是支持更多方案..
-- 通过模块支持,例如sql backend 是默认包含的,但是需要额外的依赖  了解 storage 获取更多 ..
--storage = "sql" -- Default is "internal" (Debian: "sql" requires one of the
-- lua-dbi-sqlite3, lua-dbi-mysql or lua-dbi-postgresql packages to work)
-- 如果是sql 需要 lua-dbi-mysql 等包进行工作 ....

-- For the "sql" backend, you can uncomment *one* of the below to configure:
-- 例如使用以下形式的数据库存储数据 ... 数据库 用户名 / .... 主机等信息 ....
--sql = { driver = "SQLite3", database = "prosody.sqlite" } -- Default. 'database' is the filename.
--sql = { driver = "MySQL", database = "prosody", username = "prosody", password = "secret", host = "localhost" }
--sql = { driver = "PostgreSQL", database = "prosody", username = "prosody", password = "secret", host = "localhost" }

-- 日志配置 ...
-- Logging configuration
-- For advanced logging see http://prosody.im/doc/logging
--
-- Debian:
--  Logs info and higher to /var/log
--  Logs errors to syslog also
-- 最小日志级别到控制台
log = {
	{ levels = {min = "{{ $LOG_LEVEL }}"}, to = "console"};
}
-- 全局配置
{{ if .Env.GLOBAL_CONFIG }}
{{ join "\n" (splitList "\\n" .Env.GLOBAL_CONFIG) }}
{{ end }}



-- Enable use of native prosody 0.11 support for epoll over select
-- 启动epoll 进行选择网络支持 ...
network_backend = "epoll";
-- Set the TCP backlog to 511 since the kernel rounds it up to the next power of 2: 512.
network_settings = {
  tcp_backlog = 511;
}
-- 组件网卡 ,监听任意ip 来源
component_interface = { "*" }
-- 数据配置目录
-- 后续应该改为数据库形式
data_path = "/config/data"

-- smacks
-- 在请求确认之前发送多少节
smacks_max_unacked_stanzas = 5;
-- 断开连接的会话应保持活动的秒数（以允许重新连接）
smacks_hibernation_time = 60;
-- 休眠状态下允许的会话数（每个用户限制） // 取消了,最新版不再使用 ... https://hg.prosody.im/site/rev/8152a8a121a3
smacks_max_hibernated_sessions = 1;
-- 仍然保留 h 值的具有超时休眠的允许会话数（每个用户限制）
smacks_max_old_sessions = 1;

-- 包含其他lua脚本配置
Include "conf.d/*.cfg.lua"
