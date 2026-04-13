#!/usr/bin/env bash
# Gemini CLI Windows トースト通知スクリプト
#
# 使い方:
#   bash notify.sh "メッセージ"   # 固定メッセージで通知（Stop フック用）
#   echo '{"message":"..."}' | bash notify.sh  # stdin の JSON からメッセージを取得（Notification フック用）

if [[ $# -ge 1 ]]; then
    MESSAGE="$1"
else
    INPUT=$(cat -)
    MESSAGE=$(echo "$INPUT" | jq -r '.message // "通知があります"' 2>/dev/null || echo "通知があります")
fi

TITLE="Gemini CLI"

powershell.exe -Command "
[Windows.UI.Notifications.ToastNotificationManager, Windows.UI.Notifications, ContentType = WindowsRuntime] | Out-Null;
\$template = [Windows.UI.Notifications.ToastNotificationManager]::GetTemplateContent([Windows.UI.Notifications.ToastTemplateType]::ToastText02);
\$xml = [xml]\$template.GetXml();
\$xml.toast.visual.binding.text[0].AppendChild(\$xml.CreateTextNode('${TITLE}')) | Out-Null;
\$xml.toast.visual.binding.text[1].AppendChild(\$xml.CreateTextNode('${MESSAGE}')) | Out-Null;
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
