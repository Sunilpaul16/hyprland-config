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
    return {workspaces:{values},populatedSpecialWorkspaces:populated(values), scratchpadHistory:['special:magic','special:special'], get scratchpadNames(){return [...new Set([...this.scratchpadHistory,...this.populatedSpecialWorkspaces.map(w=>w.name)])];}, focusedMonitor:{lastIpcObject:{specialWorkspace:{name:special}}}, activeToplevel:app?{lastIpcObject:{class:app,title:'Long private window title'}}:null};
}
let checks=0;
function eq(a,b){assert.strictEqual(a,b);checks++;}
eq(title(state([],''),lookup,tr),'kitty');
eq(title(state([],'','google-chrome'),lookup,tr),'Google Chrome');
eq(title(state([],'',null),lookup,tr),'Desktop');
const w=(name,windows=1)=>({name,lastIpcObject:{windows}});
const values=[w('special:music'),w('special:magic'),w('special:communication'),w('special:special'),w('special:empty',0),w('2')];
eq(title(state([w('special:magic')],'special:magic'),lookup,tr),'Scratchpad 1 · kitty');
eq(title(state(values,'special:magic'),lookup,tr),'Scratchpad 1 · kitty');
eq(title(state(values,'special:special'),lookup,tr),'Scratchpad 2 · kitty');
const body=hyprSource.split('function cycleSpecialWorkspace(direction: string): void {')[1].split('\n    function monitorNames')[0].replace(/\}\s*$/, '');
const cycle = new Function('workspaces','focusedMonitor','lastSpecialWorkspace','focusWorkspace','root','direction',body);
function step(hypr, direction, last = '') {
    let focused=hypr.focusedMonitor.lastIpcObject.specialWorkspace.name;
    hypr.runSpecialAction=(ws, animation, toggle)=>{focused=ws; hypr.lastAnimation=animation; hypr.lastToggle=toggle;};
    cycle(hypr.workspaces,hypr.focusedMonitor,last,ws=>focused=ws,hypr,direction);
    hypr.focusedMonitor.lastIpcObject.specialWorkspace.name=focused;
    return focused;
}
const hypr=state(values,'special:magic');
eq(step(hypr,'next'),'special:special');
eq(step(hypr,'previous'),'special:magic');
eq(step(hypr,'previous'),'special:magic');
// Empty slots work even with no windows anywhere; moving past the end creates one.
const empty=state([],'');
eq(step(empty,'next'),'special:magic');
eq(step(empty,'next'),'special:special');
eq(title(empty,lookup,tr),'Scratchpad 2 · kitty');
eq(step(empty,'next'),'special:scratchpad3');
eq(step(empty,'next'),'special:scratchpad4');
eq(step(empty,'previous'),'special:scratchpad3');
eq(title(empty,lookup,tr),'Scratchpad 3 · kitty');
// Closing and reopening preserves the last empty scratchpad.
empty.focusedMonitor.lastIpcObject.specialWorkspace.name='';
eq(step(empty,'next','special:scratchpad3'),'special:scratchpad3');
// Existing named scratchpads remain reachable and keep their order after emptying.
const named=state([w('special:music')],'special:special');
eq(step(named,'next'),'special:music');
named.populatedSpecialWorkspaces=[];
eq(step(named,'next'),'special:scratchpad4');
eq(step(named,'previous'),'special:music');
// A scratchpad opened outside the cycling control is included as well.
const external=state([],'special:external');
eq(step(external,'next'),'special:scratchpad4');
eq(step(external,'previous'),'special:external');
eq(empty.lastAnimation,'');
eq(named.lastAnimation,'previous');
const openBody=hyprSource.split('function openLastSpecialWorkspace(): void {')[1].split('    function toggleLastSpecialWorkspace')[0].replace(/\}\s*$/, '');
const toggleBody=hyprSource.split('function toggleLastSpecialWorkspace(): void {')[1].split('    Timer {')[0].replace(/\}\s*$/, '');
let action;
const controller={runSpecialAction:(...args)=>action=args};
const hidden={lastIpcObject:{specialWorkspace:{name:''}}};
new Function('focusedMonitor','lastSpecialWorkspace','root',openBody)(hidden,'special:special',controller);
eq(action[0],'special:special'); eq(action[2],false);
new Function('focusedMonitor','lastSpecialWorkspace','root',toggleBody)(hidden,'special:special',controller);
eq(action[0],'special:special'); eq(action[2],true);
new Function('focusedMonitor','lastSpecialWorkspace','root',toggleBody)({lastIpcObject:{specialWorkspace:{name:'special:scratchpad3'}}},'special:special',controller);
eq(action[0],'special:scratchpad3');
// An empty scratchpad must not inherit the underlying or previously focused app.
const activeBody=hyprSource.split('readonly property HyprlandToplevel activeToplevel: {')[1].split('\n    readonly property HyprlandWorkspace focusedWorkspace:')[0].replace(/\}\s*$/, '');
const active=new Function('Hyprland','focusedMonitor',activeBody);
const top=name=>({workspace:{name}});
const focused=special=>({lastIpcObject:{specialWorkspace:{name:special}}});
const regular=top('1');
const scratchpad=top('special:magic');
const normalState={activeToplevel:regular,focusedWorkspace:{toplevels:{values:[regular]}}};
eq(active(normalState,focused('special:special')),null);
eq(active({...normalState,activeToplevel:scratchpad},focused('special:special')),null);
eq(active({...normalState,activeToplevel:null},focused('special:special')),null);
eq(active({...normalState,activeToplevel:scratchpad},focused('special:magic')),scratchpad);
eq(active(normalState,focused('')),regular);
eq(active({...normalState,focusedWorkspace:{toplevels:{values:[]}}},focused('')),null);
eq(title(state([],'special:special',null),lookup,tr),'Scratchpad 2 · Desktop');
console.log(checks+' app-name, scratchpad label and cycling checks passed');
