#!/usr/bin/env bash
# Gemini CLI Windows トースト通知スクリプト

if [[ $# -ge 1 ]]; then
    MESSAGE="$1"
else
    INPUT=$(cat -)
    MESSAGE=$(echo "$INPUT" | jq -r '.message // "通知があります"' 2>/dev/null || echo "通知があります")
fi

TITLE="Gemini CLI"

# PowerShell 側でシングルクォートが壊れないようにエスケープ（' -> ''）
SAFE_MESSAGE=$(echo "$MESSAGE" | sed "s/'/''/g")
SAFE_TITLE=$(echo "$TITLE" | sed "s/'/''/g")

powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "
[Windows.UI.Notifications.ToastNotificationManager, Windows.UI.Notifications, ContentType = WindowsRuntime] | Out-Null;
\$template = [Windows.UI.Notifications.ToastNotificationManager]::GetTemplateContent([Windows.UI.Notifications.ToastTemplateType]::ToastText02);
\$xml = [xml]\$template.GetXml();
\$xml.toast.visual.binding.text[0].AppendChild(\$xml.CreateTextNode('${SAFE_TITLE}')) | Out-Null;
\$xml.toast.visual.binding.text[1].AppendChild(\$xml.CreateTextNode('${SAFE_MESSAGE}')) | Out-Null;
\$audio = \$xml.CreateElement('audio');
\$audio.SetAttribute('src', 'ms-winsoundevent:Notification.Reminder');
\$audio.SetAttribute('loop', 'false');
\$xml.toast.AppendChild(\$audio) | Out-Null;
\$serialized = New-Object -TypeName Windows.Data.Xml.Dom.XmlDocument;
\$serialized.LoadXml(\$xml.OuterXml);
\$toast = [Windows.UI.Notifications.ToastNotification]::new(\$serialized);
\$notifier = [Windows.UI.Notifications.ToastNotificationManager]::CreateToastNotifier('Gemini CLI');
\$notifier.Show(\$toast)
"
