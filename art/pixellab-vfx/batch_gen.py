"""Skill-effect styles, batch of first frames + 8-frame animations (PixelLab).
usage: python3 art/pixellab-vfx/batch_gen.py <batch-name> <state.json>   (run from the repo root)
Each style = create_image_pixen 48x48 (1 generation) + animate_image 8 frames (1 generation)."""
import json, subprocess, time, base64, sys, os, re
CLI = ['python3', 'tool/pixellab_client.py', 'call']
PIX = "16-bit pixel art, flat colour with a dark ink outline, hot bright core, centred effect on a transparent background, no text, no UI"
BATCHES = {'retry1': {
 'heavy_slash': ("one huge curved diagonal slash mark across the frame, a single white and crimson crescent blade streak with a sharp bright edge, nothing else", "the slash streak sweeps across, then thins and fades away until nothing is left"),
 'splash': ("a clean splash of blue water: a crown of droplets rising from a flat ripple ring, only water, light blue and white", "the water crown splashes up, peaks, then collapses into ripples and fades away completely")},
 'retry2': {
 'quake': ("jagged bright crack lines splitting flat ground and radiating from one point, small rock chunks flying up, dust puffs, brown earth tones, no mound, no pile", "the cracks split outward and rocks jump up, then the dust settles and everything fades away until nothing is left"),
 'holy_fire': ("a tall pillar of bright golden white fire made only of flames, a cream white core, orange tips, no torch, no handle, no base", "the pillar of fire flares up, burns at its peak, then dies down and fades away until nothing is left")},
 'batch3': {
 'zap': ("a magic bolt impact: a bright cyan and white star-shaped crackle burst with jagged lightning arcs radiating out and small sparks", "the burst flashes, the arcs spread outward, then everything fades away until nothing is left"),
 'meteor_proj': ("a blazing meteor falling diagonally, a rough dark rock wrapped in orange fire with a white-hot edge and a long trailing flame tail", "the meteor keeps falling, its flames flicker and the tail waves, a smooth repeating loop"),
 'mana': ("a swirl of blue mana: glowing blue and cyan motes spiralling around a bright white core with small star sparkles", "the motes spiral inward, the core pulses at its peak, then everything fades away until nothing is left")},
 'batch2': {
 'holy_fire': ("a column of holy fire, a white-gold flame with a cream core and orange gold tongues, a few rising golden sparks", "the holy fire flares up, burns at its peak, then dies down and fades away until nothing is left"),
 'quake': ("the ground cracking open, jagged brown fissures radiating from a centre with flying rock chunks and a ring of dust", "the ground cracks open and rocks fly up, then the dust settles and fades away"),
 'drain': ("a swirling magenta and purple vortex pulling thin streams of light into a glowing orb", "the streams spiral inward into the orb, which pulses, then fades away"),
 'fireball': ("a round fireball with a trailing flame tail, orange and yellow with a white-hot core", "the fireball flies and flickers, then bursts into sparks and fades away"),
 'wind': ("three curling gusts of wind, pale teal and white swirling lines with a few small leaves", "the gusts swirl outward and thin out until they vanish"),
 'whirl': ("a spinning ring of circular blade streaks around a centre, silver and white with sharp edges", "the blade ring spins faster, then thins out and fades away"),
 'smoke': ("a billowing puff of grey smoke, rounded grey and dark blue-grey clouds", "the smoke puffs outward, billows, then thins and fades away"),
 'volley': ("three wooden arrows raining down diagonally with white motion streaks", "the arrows fall and land with small flashes, then fade away"),
 'claw': ("three parallel claw slash marks, white with red edges and a few sparks", "the claw marks rake across one after another, then fade away"),
 'slash': ("a clean diagonal sword slash, a silver-white crescent with a bright edge and a few sparks", "the slash sweeps across then thins and fades away")},
 'batch1': {
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
            r = call('create_image_pixen', {"description": B[k][0] + ", " + PIX, "width": 48, "height": 48, "no_background": True, "seed": int(os.environ.get("SEED", "61"))})
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
