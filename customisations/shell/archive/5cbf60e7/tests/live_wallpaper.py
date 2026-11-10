from pathlib import Path
import json,subprocess,time
p=Path.home()/'.config/caelestia/shell.json'
helper=Path.home()/'.config/caelestia/animated-wallpaper.py'
def ipc(target,action):
 return subprocess.check_output(['qs','-c','caelestia','ipc','call',target,action],text=True).strip()
def setting(enabled):
 data=json.loads(p.read_text());data.setdefault('background',{})['wallpaperEnabled']=enabled
 temp=p.with_suffix('.audit-tmp');temp.write_text(json.dumps(data,indent=4)+'\n');temp.replace(p)
def wait(expected):
 for _ in range(60):
  state=subprocess.check_output(['systemctl','--user','show','caelestia-wallpaper.service','-p','ActiveState','-p','MainPID'],text=True).strip()
  if ('ActiveState='+expected) in state:
   time.sleep(.7)
   state=subprocess.check_output(['systemctl','--user','show','caelestia-wallpaper.service','-p','ActiveState','-p','MainPID'],text=True).strip()
   if ('ActiveState='+expected) in state:return state
  time.sleep(.25)
 raise RuntimeError(state)
original_static=json.loads(p.read_text()).get('background',{}).get('wallpaperEnabled',True)
original_game=ipc('gameMode','isEnabled').lower()=='true'
try:
 for static,game,expected in [(True,False,'inactive'),(False,False,'active'),(False,True,'inactive'),(True,True,'inactive'),(True,False,'inactive')]:
  setting(static);ipc('gameMode','enable' if game else 'disable');time.sleep(1)
  state=wait(expected)
  print(f'Static={static} Game={game}: {state.replace(chr(10)," ")}',flush=True)
 # Switching wallpaper while static must not launch video or alter the selected source.
 selected=json.loads((Path.home()/'.local/state/caelestia/animated-wallpaper.json').read_text())
 subprocess.run(['python3',str(helper),'set',selected['preview']],check=True)
 wait('inactive');print('Selecting a wallpaper in static mode stays stopped',flush=True)
 # Restart while game mode is active with static disabled; this catches stale mode state.
 setting(False);ipc('gameMode','enable');time.sleep(1);wait('inactive')
 subprocess.run(['qs','-c','caelestia','kill'],check=True)
 time.sleep(.8)
 subprocess.run(['caelestia','shell','-d'],check=True)
 time.sleep(2)
 print('Game mode after shell restart:',ipc('gameMode','isEnabled'),flush=True)
 wait('inactive')
 assert ipc('gameMode','isEnabled').lower()=='true','Game mode lost on shell restart'
 print('Game mode survives shell restart without video playback',flush=True)
finally:
 setting(original_static)
 ipc('gameMode','enable' if original_game else 'disable')
 time.sleep(1)
 wait('inactive' if original_static or original_game else 'active')
 print('Original static wallpaper and game-mode preferences restored',flush=True)
