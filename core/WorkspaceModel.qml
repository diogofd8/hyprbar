pragma Singleton

import Quickshell
import Quickshell.Hyprland

import qs
import qs.core as Core

//
// Hyprland workspaces, fully native — no scripts, no polling.
//
// The slot list is whatever Hyprland currently has, unioned with a floor of
// Settings.minWorkspaceCount. The floor matters because hyprland.lua declares
// five persistent workspaces and Hyprland's list is empty for the first couple
// of seconds after launch, so rendering only what exists would make the bar
// shuffle on startup. The union matters because Hyprland creates workspaces on
// demand — the next-workspace gesture past the last one spawns a new one, and
// the bar grows a pip for it without anything being reconfigured.
//
// Consumers get a plain-object list (`slots`) and one verb (`activate`).
// Nothing here knows what a workspace looks like — icons and colours are the
// module's business, keyed off `state`.
//
Singleton {
    id: root

    // What a slot is doing right now. Mutually exclusive, highest priority
    // first: a focused workspace reads as Active even if it was urgent, since
    // focusing it is what clears the urgency.
    enum State {
        Active,   // currently displayed on its monitor
        Urgent,   // demanding attention
        Occupied, // has windows, not displayed
        Empty     // no windows, or no compositor object yet
    }

    // One snapshot per slot: { id, name, state, workspace }.
    //
    // Reading the workspace properties inside this binding is what subscribes
    // it to them — the list re-evaluates whenever any workspace changes.
    readonly property var slots: {
        const live = {};
        for (const ws of Hyprland.workspaces.values) {
            // Special workspaces (scratchpads) carry negative ids and are not
            // part of the numbered strip.
            if (ws.id > 0)
                live[ws.id] = ws;
        }

        // Which ids get a pip: the floor, plus anything the compositor has
        // beyond it. A workspace that exists out of sequence (say 9, from
        // moving a window straight to it) adds only its own pip — the gap
        // below it is not padded with slots Hyprland does not have.
        const ids = {};
        for (let id = 1; id <= Settings.minWorkspaceCount; id++)
            ids[id] = true;
        for (const id in live)
            ids[id] = true;

        const out = [];
        for (const id of Object.keys(ids).map(Number).sort((a, b) => a - b)) {
            const ws = live[id] ?? null;
            out.push({
                id: id,
                name: ws ? ws.name : String(id),
                state: root.stateOf(ws),
                // The live object, when the compositor has one.
                workspace: ws
            });
        }
        return out;
    }

    // Focus a slot, as handed out by `slots`.
    function activate(slot): void {
        // activate() is the native path and needs no dispatcher string, which
        // matters here: hyprland.lua hijacks Hyprland's string dispatchers, so
        // only the lua form works when we have to fall back.
        if (slot.workspace)
            slot.workspace.activate();
        else
            Core.Actions.focusWorkspace(String(slot.id));
    }

    // `ws` is a HyprlandWorkspace, or null when the compositor has no object
    // for that slot yet.
    function stateOf(ws): int {
        if (!ws)
            return WorkspaceModel.State.Empty;

        if (ws.active)
            return WorkspaceModel.State.Active;

        if (ws.urgent)
            return WorkspaceModel.State.Urgent;

        return ws.toplevels.values.length > 0
            ? WorkspaceModel.State.Occupied
            : WorkspaceModel.State.Empty;
    }
}
