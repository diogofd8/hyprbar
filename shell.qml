//@ pragma UseQApplication

import Quickshell
import QtQuick

import qs.bar
import qs.components

ShellRoot {
    id: shell

    Bar {
        id: bar
        popoutHost: popoutHost
    }

    PopoutHost {
        id: popoutHost
        bar: bar
    }
}
