"""Uploads the menu photos in assets/menu/ to the Supabase `menu-images` bucket.

The menu items imported from the PDF booklet already point at
menu/<branch_id>/pdf-menu/<file>.jpg, so the photos show up once this runs.
Storage only accepts uploads from POS staff, so sign in with a POS login.

Usage:  python3 tool/upload_menu_images.py
        (or set POS_EMAIL and POS_PASSWORD to skip the prompts)
"""
import getpass
import json
import os
import pathlib
import re
import urllib.request

ROOT = pathlib.Path(__file__).resolve().parent.parent
BRANCH_ID = 'f9222fe0-3356-4473-883f-d38f192d0efb'  # Pizza Hub 2 (website branch)
FOLDER = f'menu/{BRANCH_ID}/pdf-menu'

config = (ROOT / 'lib/core/constants/supabase_config.dart').read_text()
url = re.search(r"url = '([^']+)'", config).group(1)
anon_key = re.search(r"anonKey = '([^']+)'", config).group(1)


def request(method, path, body, headers):
    req = urllib.request.Request(url + path, data=body, method=method,
                                 headers={'apikey': anon_key, **headers})
    with urllib.request.urlopen(req) as res:
        return json.loads(res.read() or b'{}')


email = os.environ.get('POS_EMAIL') or input('POS email: ').strip()
password = os.environ.get('POS_PASSWORD') or getpass.getpass('POS password: ')
session = request('POST', '/auth/v1/token?grant_type=password',
                  json.dumps({'email': email, 'password': password}).encode(),
                  {'Content-Type': 'application/json'})
token = session['access_token']

files = sorted((ROOT / 'assets/menu').glob('*.jpg'))
for f in files:
    request('POST', f'/storage/v1/object/menu-images/{FOLDER}/{f.name}', f.read_bytes(),
            {'Authorization': f'Bearer {token}', 'Content-Type': 'image/jpeg', 'x-upsert': 'true'})
    print('uploaded', f.name)
print(f'Done: {len(files)} photos uploaded.')
