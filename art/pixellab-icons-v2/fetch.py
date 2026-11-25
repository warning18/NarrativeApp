"""Fetch the latest job of each id: python3 art/pixellab-icons-v2/fetch.py wave2"""
import json,subprocess,sys,os
w=sys.argv[1];j=json.load(open(f'art/pixellab-icons-v2/jobs_{w}.json'));bad=[]
for k,l in j.items():
    for n,i in enumerate(l):
        out=f'art/pixellab-icons-v2/raw_{w}/{k}_{n}'
        if os.path.exists(out+'/get_image_0.png'):continue
        r=subprocess.run(['python3','tool/pixellab_client.py','call','get_image',json.dumps({"job_id":i}),'--save',out],capture_output=True,text=True).stdout
        if 'completed' not in r.split('\n')[0]: bad.append((k,n,r.split('\n')[0]))
print('not ready',bad)
