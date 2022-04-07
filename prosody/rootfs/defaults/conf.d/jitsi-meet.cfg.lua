-- 启用认证 ??
{{ $ENABLE_AUTH := .Env.ENABLE_AUTH | default "0" | toBool }}
-- 游客 域
{{ $ENABLE_GUEST_DOMAIN := and $ENABLE_AUTH (.Env.ENABLE_GUESTS | default "0" | toBool)}}
-- 认证类型 / 默认是 internal
{{ $AUTH_TYPE := .Env.AUTH_TYPE | default "internal" }}
{{ $JWT_ASAP_KEYSERVER := .Env.JWT_ASAP_KEYSERVER | default "" }}
{{ $JWT_ALLOW_EMPTY := .Env.JWT_ALLOW_EMPTY | default "0" | toBool }}
{{ $JWT_AUTH_TYPE := .Env.JWT_AUTH_TYPE | default "token" }}
{{ $MATRIX_UVS_ISSUER := .Env.MATRIX_UVS_ISSUER | default "issuer" }}
{{ $MATRIX_UVS_SYNC_POWER_LEVELS := .Env.MATRIX_UVS_SYNC_POWER_LEVELS | default "0" | toBool }}
{{ $JWT_TOKEN_AUTH_MODULE := .Env.JWT_TOKEN_AUTH_MODULE | default "token_verification" }}
{{ $ENABLE_LOBBY := .Env.ENABLE_LOBBY | default "true" | toBool }}
{{ $ENABLE_AV_MODERATION := .Env.ENABLE_AV_MODERATION | default "true" | toBool }}
{{ $ENABLE_BREAKOUT_ROOMS := .Env.ENABLE_BREAKOUT_ROOMS | default "true" | toBool }}
{{ $ENABLE_XMPP_WEBSOCKET := .Env.ENABLE_XMPP_WEBSOCKET | default "1" | toBool }}
{{ $PUBLIC_URL := .Env.PUBLIC_URL | default "https://localhost:8443" -}}
{{ $TURN_PORT := .Env.TURN_PORT | default "443" }}
{{ $TURNS_PORT := .Env.TURNS_PORT | default "443" }}
{{ $XMPP_MUC_DOMAIN_PREFIX := (split "." .Env.XMPP_MUC_DOMAIN)._0 }}
{{ $DISABLE_POLLS := .Env.DISABLE_POLLS | default "false" | toBool -}}
{{ $ENABLE_SUBDOMAINS := .Env.ENABLE_SUBDOMAINS | default "true" | toBool -}}

-- 服务器管理员
admins = {
    "{{ .Env.JICOFO_AUTH_USER }}@{{ .Env.XMPP_AUTH_DOMAIN }}",
    "{{ .Env.JVB_AUTH_USER }}@{{ .Env.XMPP_AUTH_DOMAIN }}"
}
-- 不限制的jids 取决于限速模块 	Set of JIDs exempt from limits (added in 0.12.0) https://prosody.im/doc/modules/mod_limits
unlimited_jids = {
    "{{ .Env.JICOFO_AUTH_USER }}@{{ .Env.XMPP_AUTH_DOMAIN }}",
    "{{ .Env.JVB_AUTH_USER }}@{{ .Env.XMPP_AUTH_DOMAIN }}"
}
-- 插件路径
-- 启动时查找 ...
plugin_paths = { "/prosody-plugins/", "/prosody-plugins-custom" }

-- muc mapper 域名base
muc_mapper_domain_base = "{{ .Env.XMPP_DOMAIN }}";
-- 前缀
muc_mapper_domain_prefix = "{{ $XMPP_MUC_DOMAIN_PREFIX }}";
-- http 默认主机
http_default_host = "{{ .Env.XMPP_DOMAIN }}"

{{ if .Env.TURN_CREDENTIALS }}
external_service_secret = "{{.Env.TURN_CREDENTIALS}}";
{{ end }}
-- 可以看出 TURN 服务器是一个外部服务
{{ if or .Env.TURN_HOST .Env.TURNS_HOST }}
-- 配置外部服务
external_services = {
  {{ if .Env.TURN_HOST }}
     { type = "turn", host = "{{ .Env.TURN_HOST }}", port = {{ $TURN_PORT }}, transport = "tcp", secret = true, ttl = 86400, algorithm = "turn" }
  {{ end }}
  {{ if and .Env.TURN_HOST .Env.TURNS_HOST }}
  ,
  {{ end }}
  {{ if .Env.TURNS_HOST }}
     { type = "turns", host = "{{ .Env.TURNS_HOST }}", port = {{ $TURNS_PORT }}, transport = "tcp", secret = true, ttl = 86400, algorithm = "turn" }
  {{ end }}
};
{{ end }}

-- 启动认证 , 并且
{{ if and $ENABLE_AUTH (eq $AUTH_TYPE "jwt") .Env.JWT_ACCEPTED_ISSUERS }}
asap_accepted_issuers = { "{{ join "\",\"" (splitList "," .Env.JWT_ACCEPTED_ISSUERS) }}" }
{{ end }}
--
{{ if and $ENABLE_AUTH (eq $AUTH_TYPE "jwt") .Env.JWT_ACCEPTED_AUDIENCES }}
asap_accepted_audiences = { "{{ join "\",\"" (splitList "," .Env.JWT_ACCEPTED_AUDIENCES) }}" }
{{ end }}

-- bosh 配置
-- 即使未加密 也认为是安全的,否则如果为false,那么未加密的时候 不可能连接 ...
consider_bosh_secure = true;

-- Deprecated in 0.12
-- https://github.com/bjc/prosody/commit/26542811eafd9c708a130272d7b7de77b92712de
-- XMPP 跨域为 公共IP
{{ $XMPP_CROSS_DOMAINS := $PUBLIC_URL }}
{{ $XMPP_CROSS_DOMAIN := .Env.XMPP_CROSS_DOMAIN | default "" }}
-- 如果等于 True
{{ if eq $XMPP_CROSS_DOMAIN "true"}}
-- websocket 允许跨域
cross_domain_websocket = true
-- bosh 允许跨域
cross_domain_bosh = true
{{ else }}
{{ if not (eq $XMPP_CROSS_DOMAIN "false") }}
    -- 否则如果为非false
    -- 手动处理需要跨域的列表,这里XMPP_CROSS_DOMAIN 必然是一个逗号分隔的列表
    -- 至少允许PUBLIC_URL 服务器允许跨域...
  {{ $XMPP_CROSS_DOMAINS = list $PUBLIC_URL (print "https://" .Env.XMPP_DOMAIN) .Env.XMPP_CROSS_DOMAIN | join "," }}
{{ end }}
-- 针对于特定的域来说 允许跨域 ...
cross_domain_websocket = { "{{ join "\",\"" (splitList "," $XMPP_CROSS_DOMAINS) }}" }
cross_domain_bosh = { "{{ join "\",\"" (splitList "," $XMPP_CROSS_DOMAINS) }}" }
{{ end }}
-- 设置虚拟主机 ...
VirtualHost "{{ .Env.XMPP_DOMAIN }}"
{{ if $ENABLE_AUTH }}
  {{ if eq $AUTH_TYPE "jwt" }}
    authentication = "{{ $JWT_AUTH_TYPE }}"
    app_id = "{{ .Env.JWT_APP_ID }}"
    app_secret = "{{ .Env.JWT_APP_SECRET }}"
    allow_empty_token = {{ $JWT_ALLOW_EMPTY }}
    {{ if $JWT_ASAP_KEYSERVER }}
    asap_key_server = "{{ .Env.JWT_ASAP_KEYSERVER }}"
    {{ end }}
  {{ else if eq $AUTH_TYPE "ldap" }}
    authentication = "cyrus"
    cyrus_application_name = "xmpp"
    allow_unencrypted_plain_auth = true
    -- 这种认证类型不明白 ...
  {{ else if eq $AUTH_TYPE "matrix" }}
    authentication = "matrix_user_verification"
    app_id = "{{ $MATRIX_UVS_ISSUER }}"
    uvs_base_url = "{{ .Env.MATRIX_UVS_URL }}"
    {{ if .Env.MATRIX_UVS_AUTH_TOKEN }}
    uvs_auth_token = "{{ .Env.MATRIX_UVS_AUTH_TOKEN }}"
    {{ end }}
    {{ if $MATRIX_UVS_SYNC_POWER_LEVELS }}
    uvs_sync_power_levels = true
    {{ end }}
  -- 默认形式  内部hash
  {{ else if eq $AUTH_TYPE "internal" }}
    authentication = "internal_hashed"
  {{ end }}
{{ else }}
  -- 否则匿名
  -- 很多都是jitsi 自己的组件
    authentication = "jitsi-anonymous"
{{ end }}
    ssl = {
        key = "/config/certs/{{ .Env.XMPP_DOMAIN }}.key";
        certificate = "/config/certs/{{ .Env.XMPP_DOMAIN }}.crt";
    }
    modules_enabled = {
        "bosh";
        {{ if $ENABLE_XMPP_WEBSOCKET }}
        "websocket";
        -- XMPP 有一个可选的扩展（XEP-0198：流管理），当客户端和服务器都支持它时，它可以允许客户端恢复断开的会话，并防止消息丢失。
        "smacks"; -- XEP-0198: Stream Management
        {{ end }}
        -- 收发 ...
        "pubsub";
        "ping";
        "speakerstats";
        -- 会议时常
        "conference_duration";
        {{ if or .Env.TURN_HOST .Env.TURNS_HOST }}
        "external_services";
        {{ end }}
        {{ if $ENABLE_LOBBY }}
        "muc_lobby_rooms";
        {{ end }}
        {{ if $ENABLE_BREAKOUT_ROOMS }}
        "muc_breakout_rooms";
        {{ end }}
        {{ if $ENABLE_AV_MODERATION }}
        "av_moderation";
        {{ end }}
        {{ if .Env.XMPP_MODULES }}
        "{{ join "\";\n\"" (splitList "," .Env.XMPP_MODULES) }}";
        {{ end }}
        {{ if and $ENABLE_AUTH (eq $AUTH_TYPE "ldap") }}
            "auth_cyrus";
        {{end}}
    }
    -- 需要根据它 配置
    main_muc = "{{ .Env.XMPP_MUC_DOMAIN }}"

    {{ if $ENABLE_LOBBY }}
    lobby_muc = "lobby.{{ .Env.XMPP_DOMAIN }}"
    {{ if .Env.XMPP_RECORDER_DOMAIN }}
    muc_lobby_whitelist = { "{{ .Env.XMPP_RECORDER_DOMAIN }}" }
    {{ end }}
    {{ end }}

    {{ if $ENABLE_BREAKOUT_ROOMS }}
    breakout_rooms_muc = "breakout.{{ .Env.XMPP_DOMAIN }}"
    {{ end }}

    speakerstats_component = "speakerstats.{{ .Env.XMPP_DOMAIN }}"
    conference_duration_component = "conferenceduration.{{ .Env.XMPP_DOMAIN }}"

    {{ if $ENABLE_AV_MODERATION }}
    av_moderation_component = "avmoderation.{{ .Env.XMPP_DOMAIN }}"
    {{ end }}
    -- 客户端 服务器端的连接  不需要加密 ..
    c2s_require_encryption = false
-- 游客域 ...
{{ if $ENABLE_GUEST_DOMAIN }}
VirtualHost "{{ .Env.XMPP_GUEST_DOMAIN }}"
    authentication = "jitsi-anonymous"

    c2s_require_encryption = false
{{ end }}
-- 认证域
VirtualHost "{{ .Env.XMPP_AUTH_DOMAIN }}"
    ssl = {
        key = "/config/certs/{{ .Env.XMPP_AUTH_DOMAIN }}.key";
        certificate = "/config/certs/{{ .Env.XMPP_AUTH_DOMAIN }}.crt";
    }
    modules_enabled = {
        "limits_exception";
    }
    -- 验证内部hashed
    authentication = "internal_hashed"
-- 记录器的域
{{ if .Env.XMPP_RECORDER_DOMAIN }}
VirtualHost "{{ .Env.XMPP_RECORDER_DOMAIN }}"
    modules_enabled = {
    -- XMPP Ping reply support
      "ping";
    }
    authentication = "internal_hashed"
{{ end }}
-- 使用插件muc (创建一个聊天室)
Component "{{ .Env.XMPP_INTERNAL_MUC_DOMAIN }}" "muc"
    storage = "memory"
    modules_enabled = {
        "ping";
        {{ if .Env.XMPP_INTERNAL_MUC_MODULES -}}
        "{{ join "\";\n\"" (splitList "," .Env.XMPP_INTERNAL_MUC_MODULES) }}";
        {{ end -}}
    }
    -- 限制房间的产生
    -- 仅仅只有管理员才能创建房间
    restrict_room_creation = true
    -- 锁 ??
    -- false,表示房间无需在配置之后使用
    -- 将此设置设置为 false 可能会破坏一些希望能够“创建”房间的客户端。它还引入了一种竞争条件，在这种情况下，其他用户可能会在配置为私人房间之前进入该房间。
    muc_room_locking = false
    --
    muc_room_default_public_jids = true

--[[      muc_room_default_public = true // 公开
           muc_room_default_persistent = false // 持久化
           muc_room_default_members_only = false // 仅成员
           muc_room_default_moderated = false // 控制
           muc_room_default_public_jids = false // 公开jid
           muc_room_default_change_subject = false // 改变主题
           muc_room_default_history_length = 20 // 历史记录keep-alive
           muc_room_default_language = "en" ]] // 语言

Component "{{ .Env.XMPP_MUC_DOMAIN }}" "muc"
    -- 这个在内存中存储  测试环境 ..
    storage = "memory"
    modules_enabled = {
        "muc_meeting_id";
        {{ if .Env.XMPP_MUC_MODULES -}}
        "{{ join "\";\n\"" (splitList "," .Env.XMPP_MUC_MODULES) }}";
        {{ end -}}
        {{ if and $ENABLE_AUTH (eq $AUTH_TYPE "jwt") -}}
        "{{ $JWT_TOKEN_AUTH_MODULE }}";
        {{ end }}
        {{ if and $ENABLE_AUTH (eq $AUTH_TYPE "matrix") $MATRIX_UVS_SYNC_POWER_LEVELS -}}
        "matrix_power_sync";
        {{ end -}}

        {{ if not $DISABLE_POLLS -}}
        "polls";
        {{ end -}}
        -- 子域映射组件
        {{ if $ENABLE_SUBDOMAINS -}}
            "muc_domain_mapper";
        {{ end -}}
    }
    -- 内存中房间的个数为 1000
    muc_room_cache_size = 1000
    -- false
    muc_room_locking = false
    -- 默认公开jid ??
    muc_room_default_public_jids = true

-- 增加一个组件(服务),也可以说自定义的虚拟主机 ...
Component "focus.{{ .Env.XMPP_DOMAIN }}" "client_proxy"
    -- 目标地址 用户@HOST
    -- 自己写的组件  支持此属性
    target_address = "{{ .Env.JICOFO_AUTH_USER }}@{{ .Env.XMPP_AUTH_DOMAIN }}"
-- 演讲统计
Component "speakerstats.{{ .Env.XMPP_DOMAIN }}" "speakerstats_component"
    muc_component = "{{ .Env.XMPP_MUC_DOMAIN }}"
-- 会话时常
Component "conferenceduration.{{ .Env.XMPP_DOMAIN }}" "conference_duration_component"
    muc_component = "{{ .Env.XMPP_MUC_DOMAIN }}"
-- A/V 控制
{{ if $ENABLE_AV_MODERATION }}
Component "avmoderation.{{ .Env.XMPP_DOMAIN }}" "av_moderation_component"
    muc_component = "{{ .Env.XMPP_MUC_DOMAIN }}"
{{ end }}

{{ if $ENABLE_LOBBY }}
Component "lobby.{{ .Env.XMPP_DOMAIN }}" "muc"
    storage = "memory"
    restrict_room_creation = true
    muc_room_locking = false
    muc_room_default_public_jids = true
{{ end }}

{{ if $ENABLE_BREAKOUT_ROOMS }}
Component "breakout.{{ .Env.XMPP_DOMAIN }}" "muc"
    storage = "memory"
    restrict_room_creation = true
    muc_room_locking = false
    muc_room_default_public_jids = true
    modules_enabled = {
        "muc_meeting_id";
        {{ if $ENABLE_SUBDOMAINS -}}
        "muc_domain_mapper";
        {{ end -}}
        {{ if not $DISABLE_POLLS -}}
        "polls";
        {{ end -}}
    }
{{ end }}
