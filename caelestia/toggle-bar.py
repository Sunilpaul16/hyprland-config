from pathlib import Path
import json, subprocess
p=Path.home()/'.config/caelestia/shell.json'
data=json.loads(p.read_text()) if p.exists() else {}
bar=data.setdefault('bar', {})
bar['persistent']=not bar.get('persistent', True)
bar['showOnHover']=False
p.write_text(json.dumps(data,indent=4)+'\n')
# Clear any temporary reveal so persistence alone controls the bar.
result=subprocess.run(['qs','-c','caelestia','ipc','call','drawers','isOpen','bar'],capture_output=True,text=True)
if result.stdout.strip()=='1':
    subprocess.run(['qs','-c','caelestia','ipc','call','drawers','toggle','bar'],check=True)
