//@ pragma IconTheme Papirus-Dark

import QtQuick
import Quickshell
import "core"
import "services"
import "utils"
import "./components"
import "modules/bar"
import "modules/launcher"

ShellRoot {
    ThemeLoader { }

    Item {
        visible: false
        Component.onCompleted: {
            NetworkStatusService.refresh()
            SystemMonitorService.refresh()
        }
    }

    Variants {
        model: Quickshell.screens
        Bar { }
    }

    UnifiedLauncher { id: globalLauncher }
}
