const fs = require('fs');
const assert = require('assert');
const path = require('path');
const base = process.env.SHELL_CONFIG || path.join(__dirname, '..', 'quickshell', 'caelestia');
const titleSource = fs.readFileSync(path.join(base,'modules/bar/components/ActiveWindow.qml'),'utf8');
const hyprSource = fs.readFileSync(path.join(base,'services/Hypr.qml'),'utf8');
const titleBody = titleSource.split('readonly property string windowTitle: {')[1].split('\n    readonly property int maxHeight:')[0].replace(/\}\s*$/, '');
const title = new Function('Hypr','DesktopEntries','Tr',titleBody);
const lookup = {heuristicLookup: c => c === 'google-chrome' ? {name:'Google Chrome'} : null};
const tr = {trCtx: text => text};
function populated(values) {
    if (hyprSource.includes('readonly property var populatedSpecialWorkspaces:')) {
        const expression = hyprSource.split('readonly property var populatedSpecialWorkspaces:')[1].split('\n\n')[0].trim();
        return new Function('workspaces','return '+expression)({values});
    }
    return values.filter(w=>w.name.startsWith('special:') && w.lastIpcObject.windows>0);
}
function state(values, special, app='kitty') {
    return {workspaces:{values},populatedSpecialWorkspaces:populated(values), focusedMonitor:{lastIpcObject:{specialWorkspace:{name:special}}}, activeToplevel:app?{lastIpcObject:{class:app,title:'Long private window title'}}:null};
}
let checks=0;
function eq(a,b){assert.strictEqual(a,b);checks++;}
eq(title(state([],''),lookup,tr),'kitty');
eq(title(state([],'','google-chrome'),lookup,tr),'Google Chrome');
eq(title(state([],'',null),lookup,tr),'Desktop');
const w=(name,windows=1)=>({name,lastIpcObject:{windows}});
const values=[w('special:music'),w('special:magic'),w('special:communication'),w('special:special'),w('special:empty',0),w('2')];
eq(title(state([w('special:magic')],'special:magic'),lookup,tr),'Scratchpad · kitty');
eq(title(state(values,'special:magic'),lookup,tr),'Scratchpad 1 · kitty');
eq(title(state(values,'special:special'),lookup,tr),'Scratchpad 2 · kitty');
const body=hyprSource.split('function cycleSpecialWorkspace(direction: string): void {')[1].split('\n    function monitorNames')[0].replace(/\}\s*$/, '');
const hypr=state(values,'special:magic');
let focused;
new Function('workspaces','focusedMonitor','lastSpecialWorkspace','focusWorkspace','root','direction',body)(hypr.workspaces,hypr.focusedMonitor,'',ws=>focused=ws,hypr,'next');
eq(focused,'special:special');
new Function('workspaces','focusedMonitor','lastSpecialWorkspace','focusWorkspace','root','direction',body)(hypr.workspaces,hypr.focusedMonitor,'',ws=>focused=ws,hypr,'previous');
eq(focused,'special:music');
console.log(checks+' app-name, scratchpad label and cycling checks passed');
