#!/usr/bin/env bash
# Claude Code Windows トースト通知スクリプト

if [[ $# -ge 1 ]]; then
    MESSAGE="$1"
else
    INPUT=$(cat -)
    MESSAGE=$(echo "$INPUT" | jq -r '.message // "通知があります"' 2>/dev/null || echo "通知があります")
fi

TITLE="Claude Code"

powershell.exe -NoProfile -Command - <<EOF
[Windows.UI.Notifications.ToastNotificationManager, Windows.UI.Notifications, ContentType = WindowsRuntime] | Out-Null
\$template = [Windows.UI.Notifications.ToastNotificationManager]::GetTemplateContent([Windows.UI.Notifications.ToastTemplateType]::ToastText02)
\$xml = [xml]\$template.GetXml()
\$xml.toast.visual.binding.text[0].AppendChild(\$xml.CreateTextNode("${TITLE}")) | Out-Null
\$xml.toast.visual.binding.text[1].AppendChild(\$xml.CreateTextNode("${MESSAGE}")) | Out-Null
\$audio = \$xml.CreateElement("audio")
\$audio.SetAttribute("src", "ms-winsoundevent:Notification.Reminder")
\$audio.SetAttribute("loop", "false")
\$xml.toast.AppendChild(\$audio) | Out-Null
\$serialized = New-Object -TypeName Windows.Data.Xml.Dom.XmlDocument
\$serialized.LoadXml(\$xml.OuterXml)
\$toast = [Windows.UI.Notifications.ToastNotification]::new(\$serialized)
\$notifier = [Windows.UI.Notifications.ToastNotificationManager]::CreateToastNotifier("Claude Code")
\$notifier.Show(\$toast)
EOF
