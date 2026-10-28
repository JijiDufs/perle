#!/usr/bin/env python3
"""Écrit une partie « vitrine » dans le simulateur démarré (app installée, partie sur le téléphone)
pour les captures App Store : collection fournie (perles, trouvailles, bijoux), 1 240 ✦, niveau 14, et l'huître
posée contient la perle voulue. La partie passe par vitrine/ (le vrai moteur) : succès, niveau et bijoux cohérents.
usage: python3 seed.py <pearlId|find:<id>> [skin] [stock] [dust] [écrins à ouvrir] [rareté de l'écrin posé:variante]
       ex. seed.py golden lagon 10 1240 3 rubis:aurore   (puis relancer l'app)"""
import json, sys, time, subprocess, random

import os
ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), '..', '..'))
CAT = json.load(open(os.path.join(ROOT, 'ios/PearlCore/Sources/PearlCore/Resources/catalog.json')))
PEARLS = {p['id']: p for p in CAT['pearls']}
random.seed(7)
now = time.time() * 1000

def traits(pid, mark=None, overtone=None, shape=None):
    sw = CAT['shapeWeights'][pid]; ow = CAT['overtoneWeights'][pid]
    return {'shape': shape or sw[0]['id'], 'overtone': overtone or ow[0]['id'], 'mark': mark, 'seed': round(random.random(), 3)}

def value(pid, size, t):
    p = PEARLS[pid]
    if p['baseValue'] == 0: return 0
    f = size / ((p['sizeMm'][0] + p['sizeMm'][1]) / 2)
    f *= CAT['shapes'][t['shape']]['value'] * CAT['overtones'][t['overtone']]['value']
    if t['mark']: f *= CAT['marks'][t['mark']]['value']
    return round(p['baseValue'] * f)

serial = 1
cards = []
def card(pid, size, lustre, mark=None, overtone=None, shape=None, age_min=0):
    global serial
    t = traits(pid, mark, overtone, shape)
    cards.append({'serial': serial, 'pearlId': pid, 'sizeMm': size, 'value': value(pid, size, t), 'lustre': lustre,
                  'cracked': False, 'foundAt': now - age_min * 60000, 'traits': t})
    serial += 1

# Une collection de joueur régulier : beaucoup de communes, quelques rares, pas encore la maudite.
for i in range(14): card('white', round(5 + random.random() * 2.5, 1), random.choice('SABBC'), age_min=3000 - i)
for i in range(9): card('rose', round(6 + random.random() * 2.5, 1), random.choice('SAAB'), age_min=2500 - i)
for i in range(6): card('baroque', round(7 + random.random() * 4, 1), random.choice('SAB'), age_min=2000 - i)
card('baroque', 10.2, 'S', mark='coeur', age_min=1500)
for i in range(3): card('black', round(9 + random.random() * 4, 1), random.choice('SA'), overtone=None, age_min=1200 - i)
card('black', 12.6, 'S', overtone='vert-paon', mark='etoile', age_min=900)
card('golden', 13.1, 'S', age_min=600)
card('golden', 11.4, 'A', mark='lune', age_min=300)
card('giant', 24.8, 'A', age_min=60)

finds = []
for fid in ['canard', 'coeur-ocean', 'cartouche', 'piece-or', 'champignon', 'bouteille']:
    f = next(x for x in CAT['finds'] if x['id'] == fid)
    finds.append({'serial': serial, 'findId': fid, 'value': f['value'], 'foundAt': now - serial * 60000}); serial += 1

target = sys.argv[1] if len(sys.argv) > 1 else 'cursed'
skin = sys.argv[2] if len(sys.argv) > 2 else 'lagon'
stock = int(sys.argv[3]) if len(sys.argv) > 3 else 10
dust = int(sys.argv[4]) if len(sys.argv) > 4 else 1240
ecrins = sys.argv[5] if len(sys.argv) > 5 else '3'
ecrin, _, variant = (sys.argv[6] if len(sys.argv) > 6 else 'rubis:aurore').partition(':')
if target.startswith('find:'):
    oyster = {'pearlId': 'empty', 'sizeMm': 0, 'findId': target[5:], 'traits': None}
else:
    size = {'cursed': 13, 'golden': 13.8, 'giant': 25.6, 'black': 12.9}.get(target, 9)
    t = traits(target, overtone={'cursed': 'sang', 'black': 'vert-paon', 'golden': 'dore'}.get(target))
    oyster = {'pearlId': target, 'sizeMm': size, 'findId': None, 'traits': t}

day = time.strftime('%Y-%m-%d')
state = {
    'oyster': oyster, 'drawState': {'sinceGoldenOrBetter': 3}, 'nextSerial': serial,
    'pearlCards': cards, 'findCards': finds, 'oystersOpened': 212, 'dust': dust,
    'stock': {'count': stock, 'lastRefillAt': now}, 'ownedSkins': ['lagon', 'benitier', 'or'], 'equippedSkin': skin,
    'missions': {'day': day, 'bonusClaimed': False, 'missions': [
        {'kind': 'open', 'goal': 8, 'progress': 6, 'claimed': False},
        {'kind': 'lustreS', 'goal': 1, 'progress': 1, 'claimed': False},
        {'kind': 'rare', 'goal': 1, 'progress': 1, 'claimed': True}]},
    'noCrackStreak': 7, 'adRewards': None,
    'login': {'lastClaimDay': day, 'calendarIndex': 5, 'streak': 5, 'bestStreak': 12, 'jokerUsedDay': None},
    'reputation': 0, 'rewardedLevel': 1, 'ecrins': 0,
}
# Niveau 14, écrins, bijoux, succès et titre « Chasseur de géantes » par le vrai moteur (vitrine/).
data = subprocess.run(['swift', 'run', '-c', 'release', '--package-path', os.path.join(os.path.dirname(__file__), 'vitrine'), 'vitrine',
                       '14', ecrins, ecrin or '-', '82', variant or '-', 'perle-geante'],
                      input=json.dumps(state, ensure_ascii=False).encode(), capture_output=True, check=True).stdout
hexdata = data.hex()
dev = 'booted'
PL = subprocess.run(['xcrun','simctl','get_app_container',dev,'app.pearlinc.PearlInc','data'],capture_output=True,text=True).stdout.strip() + '/Library/Preferences/app.pearlinc.PearlInc.plist'
subprocess.run(['xcrun', 'simctl', 'terminate', dev, 'app.pearlinc.PearlInc'], capture_output=True)
# Depuis la 1.1, une partie par compte (pearlinc.player.v1.<compte>) : on écrit la vitrine partout.
import plistlib
keys = [k for k in plistlib.load(open(PL, 'rb')) if k.startswith('pearlinc.player.v1') and not k.endswith(('.sync', '.aside'))] if os.path.exists(PL) else []
for key in set(keys) | {'pearlinc.player.v1'}:
    subprocess.run(['xcrun', 'simctl', 'spawn', dev, 'defaults', 'write', PL, key, '-data', hexdata], check=True)
subprocess.run(['xcrun', 'simctl', 'spawn', dev, 'defaults', 'write', PL, 'pearlinc.calendar.offeredDay', day], check=True)
print('seeded', target, skin, len(cards), 'cards', 'écrin', ecrin, variant)
