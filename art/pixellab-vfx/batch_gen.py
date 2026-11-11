"""Skill-effect styles, batch of first frames + 8-frame animations (PixelLab).
usage: python3 art/pixellab-vfx/batch_gen.py <batch-name> <state.json>   (run from the repo root)
Each style = create_image_pixen 48x48 (1 generation) + animate_image 8 frames (1 generation)."""
import json, subprocess, time, base64, sys, os, re
CLI = ['python3', 'tool/pixellab_client.py', 'call']
PIX = "16-bit pixel art, flat colour with a dark ink outline, hot bright core, centred effect on a transparent background, no text, no UI"
BATCHES = {'batch1': {
 'radiance': ("a burst of holy golden light, a bright white core with eight radiating rays", "the light blooms outward, shines at its peak, then fades away until nothing is left"),
 'shout': ("three curved sound waves bursting outward from a roaring centre, orange and cream", "the sound waves expand outward and thin out until they vanish"),
 'stone_shield': ("a round slab of grey rock hovering as a shield, cracked and mossy edge, a hard bright rim", "the stone slab slams into place, holds, then crumbles into dust and fades away"),
 'arrow': ("an arrow impact: a wooden arrow stuck mid-air with a burst of splinters and a white flash", "the arrow lands with a flash and splinters, then fades away"),
 'shadow': ("a swirling cloud of dark violet shadow with two pale slits like eyes", "the shadow swirls up, peaks, then dissolves into wisps and fades away"),
 'pierce': ("a thin silver spear thrust with a bright tip flash and a short line of impact sparks", "the spear thrusts forward with a flash then fades away"),
 'heavy_slash': ("a huge diagonal crescent slash, bright white edge, red-orange body, a shockwave of sparks", "a heavy slash sweeps across then breaks into sparks and fades away"),
 'poison': ("a cloud of green poison gas with rising bubbles and a drip of toxic liquid", "the gas billows up, bubbles pop, then it thins out and fades away"),
 'splash': ("a splash of blue water, a crown of droplets thrown upward from a ring", "the water splashes up, peaks, then the droplets fall and fade away"),
 'impact': ("a blunt impact burst: a white star flash with a ring of dust and cracks", "the impact flashes, the ring expands, then dust fades away")}}
def call(tool, args):
    for _ in range(40):
        r = subprocess.run(CLI + [tool, json.dumps(args)], capture_output=True, text=True).stdout
        if 'rate limit' in r: time.sleep(20); continue
        return r
    return r
def field(r, k):
    m = re.search(r'^' + k + r': (\S+)', r, re.M); return m.group(1) if m else None
if __name__ == '__main__':
    name, STATE = sys.argv[1], sys.argv[2]; B = BATCHES[name]; R = f'art/pixellab-vfx/{name}/raw'
    queue = list(B); active = []; done = {}
    def save(): json.dump(dict(done=done, active=active), open(STATE, 'w'), indent=1)
    while queue or active:
        while queue and len(active) < 4:
            k = queue.pop(0)
            r = call('create_image_pixen', {"description": B[k][0] + ", " + PIX, "width": 48, "height": 48, "no_background": True, "seed": 61})
            active.append(dict(k=k, job=field(r, 'job_id'), stage='img', raw=r[:200] if not field(r, 'job_id') else ''))
            save()
        time.sleep(25)
        for a in list(active):
            if not a['job']: print('FAILED', a); active.remove(a); continue
            r = call('get_image', {"job_id": a['job']})
            if field(r, 'status') == 'completed':
                d = f"{R}/{a['k']}_{'f0' if a['stage']=='img' else 'anim'}"
                subprocess.run(CLI + ['get_image', json.dumps({"job_id": a['job']}), '--save', d], capture_output=True, text=True)
                if a['stage'] == 'img':
                    b = base64.b64encode(open(d + '/get_image_0.png', 'rb').read()).decode()
                    r2 = call('animate_image', {"first_frame_base64": b, "action": B[a['k']][1], "frame_count": 8, "no_background": True})
                    a['job'] = field(r2, 'job_id'); a['stage'] = 'anim'
                else:
                    done[a['k']] = 'ok'; active.remove(a)
        save()
    print('ALL DONE', len(done))
