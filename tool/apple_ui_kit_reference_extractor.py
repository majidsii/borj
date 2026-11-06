#!/usr/bin/env python3
import argparse, hashlib, json, zipfile
from dataclasses import dataclass
from pathlib import Path
from typing import Any

@dataclass(frozen=True)
class SourceFile:
    path: Path
    expected_sha256: str

def _sha256(path: Path)->str:
    h=hashlib.sha256()
    with path.open('rb') as f:
        for chunk in iter(lambda:f.read(1024*1024),b''): h.update(chunk)
    return h.hexdigest()

def verify_sha256(source: SourceFile)->None:
    actual=_sha256(source.path)
    if actual != source.expected_sha256:
        raise ValueError(f'SHA-256 mismatch for {source.path}: expected {source.expected_sha256}, got {actual}')

def _color(c):
    if not isinstance(c,dict): return None
    vals={k:c.get(k) for k in ('red','green','blue','alpha')}
    if not all(isinstance(vals[k],(int,float)) for k in vals): return None
    r,g,b,a=(float(vals[x]) for x in ('red','green','blue','alpha'))
    clamp=lambda v:max(0,min(255,round(v*255)))
    return {'red':r,'green':g,'blue':b,'alpha':a,'hexArgb':f'#{clamp(a):02X}{clamp(r):02X}{clamp(g):02X}{clamp(b):02X}','swatchId':c.get('swatchID')}

def _frame(f):
    if not isinstance(f,dict): return None
    return {k:f.get(k) for k in ('x','y','width','height','constrainProportions') if k in f}

def _gradient(g):
    if not isinstance(g,dict): return None
    return {'gradientType':g.get('gradientType'),'from':g.get('from'),'to':g.get('to'),'elipseLength':g.get('elipseLength'),'colorInterpolation':g.get('colorInterpolation'),'stops':[{'position':s.get('position'),'color':_color(s.get('color'))} for s in g.get('stops',[]) if isinstance(s,dict)]}

def _context(v):
    if not isinstance(v,dict): return None
    return {k:v.get(k) for k in ('blendMode','opacity','isProgressive') if k in v}

def _fill(v):
    if not isinstance(v,dict): return None
    return {'isEnabled':v.get('isEnabled'),'fillType':v.get('fillType'),'color':_color(v.get('color')),'contextSettings':_context(v.get('contextSettings')),'gradient':_gradient(v.get('gradient')),'noiseIndex':v.get('noiseIndex'),'noiseIntensity':v.get('noiseIntensity'),'patternFillType':v.get('patternFillType'),'patternTileScale':v.get('patternTileScale'),'layeringType':v.get('layeringType')}

def _border(v):
    if not isinstance(v,dict): return None
    return {'isEnabled':v.get('isEnabled'),'fillType':v.get('fillType'),'position':v.get('position'),'thickness':v.get('thickness'),'color':_color(v.get('color')),'contextSettings':_context(v.get('contextSettings')),'gradient':_gradient(v.get('gradient'))}

def _shadow(v):
    if not isinstance(v,dict): return None
    return {k:v.get(k) for k in ('isEnabled','blurRadius','offsetX','offsetY','spread','spreadIsPercent','blurType') if k in v} | {'color':_color(v.get('color')),'contextSettings':_context(v.get('contextSettings'))}

def _blur(v):
    if not isinstance(v,dict): return None
    keys=('isEnabled','type','radius','saturation','brightness','distortion','chromaticAberrationMultiplier','depth','isCustomGlass','skipLightingEffects','layeringType','center','motionAngle','extraSamplingRegion')
    return {k:v.get(k) for k in keys if k in v}

def _corners(v):
    if not isinstance(v,dict): return None
    return {k:v.get(k) for k in ('radii','style','prefersConcentric','smoothing') if k in v}

def _text_style(style):
    if not isinstance(style,dict): return None
    ts=style.get('textStyle')
    if not isinstance(ts,dict): return None
    enc=ts.get('encodedAttributes') or {}
    fd=(enc.get('MSAttributedStringFontAttribute') or {}).get('attributes') or {}
    para=enc.get('paragraphStyle') or {}
    return {'fontPostScriptName':fd.get('name'),'fontSize':fd.get('size'),'textColor':_color(enc.get('MSAttributedStringColorAttribute')),'kerning':enc.get('kerning'),'lineHeightMin':para.get('minimumLineHeight'),'lineHeightMax':para.get('maximumLineHeight'),'alignment':para.get('alignment'),'verticalAlignment':ts.get('verticalAlignment')}

def _style(style):
    if not isinstance(style,dict): return None
    return {'sourceId':style.get('do_objectID'),'contextSettings':_context(style.get('contextSettings')),'fills':[_fill(x) for x in style.get('fills',[]) if isinstance(x,dict)],'borders':[_border(x) for x in style.get('borders',[]) if isinstance(x,dict)],'shadows':[_shadow(x) for x in style.get('shadows',[]) if isinstance(x,dict)],'innerShadows':[_shadow(x) for x in style.get('innerShadows',[]) if isinstance(x,dict)],'blurs':[_blur(x) for x in style.get('blurs',[]) if isinstance(x,dict)],'corners':_corners(style.get('corners')),'text':_text_style(style)}

def _state_name(name):
    if not isinstance(name,str): return None
    known=('Idle','Hovered','Hover','Clicked','Pressed','Selected','Disabled','Focused','Active','Inactive','On','Off','Default','Tinted','Over-glass','Over Glass')
    parts=[p.strip() for p in name.replace('—','/').split('/') if p.strip()]
    for p in reversed(parts):
        if any(k.lower() in p.lower() for k in known): return p
    return None

_CANONICAL_SOURCE_FILE_NAMES={
    '839ecf260025264db9000a4ce23ef2804c33c8d62642a6373ed310858ca64171':
        'Apple iOS 27 UI Kit.sketch',
    'f5aa2f4f319eae66b5eab0bbc0faacb10ce16656457cff528f9810d57ff1354d':
        'Apple macOS 27 UI Kit.sketch',
    '4bbbb036ce008f2213803ad05d7591ed4c0ac009f677a2e1d3d3b315ceb1ce31':
        'apple-macos-27-ui-kit_assets_2026-06-23_v12.zip',
}

def _canonical_source_file_name(sha256,local_name):
    return _CANONICAL_SOURCE_FILE_NAMES.get(sha256,local_name)

_LIQUID_GLASS_USAGE_ROOT_NAMES=(
    'Liquid Glass - Over Dark Backgrounds',
    'Liquid Glass - Over Light Backgrounds',
)

def _layer_record(layer,page_name,path):
    name=layer.get('name') or ''
    rec={'sourceId':layer.get('do_objectID'),'pageName':page_name,'layerPath':'/'.join(path+[name]) if name else '/'.join(path),'name':name,'stateName':_state_name(name),'class':layer.get('_class'),'frame':_frame(layer.get('frame')),'sharedStyleId':layer.get('sharedStyleID'),'symbolId':layer.get('symbolID'),'childCount':len(layer.get('layers') or []),'rotation':layer.get('rotation'),'isVisible':layer.get('isVisible'),'opacity':_context((layer.get('style') or {}).get('contextSettings'))}
    if layer.get('_class')=='text':
        rec['textStyle']=_text_style(layer.get('style'))
        rec['attributedString']=None
    if isinstance(layer.get('style'),dict) and isinstance(layer['style'].get('corners'),dict): rec['corners']=_corners(layer['style']['corners'])
    return rec

def _liquid_glass_usage_records(layer,page_name,path,inside_usage_root=False):
    if not isinstance(layer,dict): return []
    name=layer.get('name') or ''
    is_root=name in _LIQUID_GLASS_USAGE_ROOT_NAMES
    include=inside_usage_root or is_root
    records=[]
    if include:
        records.append(_layer_record(layer,page_name,path))
    child_path=path+([name] if name else [])
    for child in layer.get('layers') or []:
        records.extend(
            _liquid_glass_usage_records(
                child,page_name,child_path,include
            )
        )
    return records

def extract_sketch_reference(source: SourceFile)->dict[str,Any]:
    verify_sha256(source)
    with zipfile.ZipFile(source.path) as z:
        doc=json.loads(z.read('document.json')); meta=json.loads(z.read('meta.json'))
        page_names=[]; layers=[]; liquid_glass_usage=[]
        page_entries=sorted(n for n in z.namelist() if n.startswith('pages/') and n.endswith('.json'))
        for entry in page_entries:
            p=json.loads(z.read(entry)); pname=p.get('name') or ''
            page_names.append({'sourceId':p.get('do_objectID'),'name':pname,'topLevelLayerCount':len(p.get('layers') or [])})
            for layer in p.get('layers') or []:
                layers.append(_layer_record(layer,pname,[]))
                liquid_glass_usage.extend(
                    _liquid_glass_usage_records(layer,pname,[],False)
                )
        swatches=[]
        for x in (doc.get('sharedSwatches') or {}).get('objects',[]):
            swatches.append({'sourceId':x.get('do_objectID'),'name':x.get('name'),'color':_color(x.get('value'))})
        text=[]
        for x in (doc.get('layerTextStyles') or {}).get('objects',[]):
            text.append({'sourceId':x.get('do_objectID'),'name':x.get('name'),'style':_style(x.get('value'))})
        lst=[]
        for x in (doc.get('layerStyles') or {}).get('objects',[]):
            lst.append({'sourceId':x.get('do_objectID'),'name':x.get('name'),'style':_style(x.get('value'))})
        fonts=[]
        for x in doc.get('fontReferences') or []:
            fonts.append({'sourceId':x.get('do_objectID'),'fontFamilyName':x.get('fontFamilyName'),'fontFileName':x.get('fontFileName'),'postscriptNames':x.get('postscriptNames') or [],'options':x.get('options')})
        key=lambda x:((x.get('name') or ''),(x.get('sourceId') or ''))
        return {'source':{'fileName':_canonical_source_file_name(_sha256(source.path),source.path.name),'sha256':_sha256(source.path),'sizeBytes':source.path.stat().st_size},'meta':{k:meta.get(k) for k in ('app','appVersion','build','version','compatibilityVersion','created','variant')},'pageCount':len(page_entries),'pages':sorted(page_names,key=key),'swatches':sorted(swatches,key=key),'textStyles':sorted(text,key=key),'layerStyles':sorted(lst,key=key),'fontReferences':sorted(fonts,key=lambda x:((x.get('fontFamilyName') or ''),(x.get('sourceId') or ''))),'componentLayers':sorted(layers,key=lambda x:((x.get('pageName') or ''),(x.get('layerPath') or ''),(x.get('sourceId') or ''))),'liquidGlassUsageLayers':sorted(liquid_glass_usage,key=lambda x:((x.get('pageName') or ''),(x.get('layerPath') or ''),(x.get('sourceId') or '')))}

def extract_asset_bundle(source: SourceFile):
    verify_sha256(source)
    with zipfile.ZipFile(source.path) as z:
      entries=[]
      for info in sorted(z.infolist(),key=lambda i:i.filename):
        if info.is_dir(): continue
        entries.append({'path':info.filename,'sizeBytes':info.file_size,'compressedSizeBytes':info.compress_size,'crc32':f'{info.CRC:08x}'})
    return {'source':{'fileName':_canonical_source_file_name(_sha256(source.path),source.path.name),'sha256':_sha256(source.path),'sizeBytes':source.path.stat().st_size},'entryCount':len(entries),'entries':entries}

def write_deterministic_json(value, output:Path)->None:
    output.parent.mkdir(parents=True,exist_ok=True)
    output.write_text(json.dumps(value,ensure_ascii=False,sort_keys=True,indent=2)+"\n")

def _component_map(family,data):
    lines=[f'## {family}', '', f'- Pages: **{data["pageCount"]}**', f'- Shared swatches: **{len(data["swatches"])}**', f'- Shared text styles: **{len(data["textStyles"])}**', f'- Shared layer styles: **{len(data["layerStyles"])}**', f'- Font references: **{len(data["fontReferences"])}**', f'- Flattened component layers: **{len(data["componentLayers"])}**','', '### Pages','']
    for p in data['pages']: lines.append(f'- `{p["name"]}` — {p["topLevelLayerCount"]} top-level layers')
    lines += ['', '### Liquid Glass layer styles','']
    lg=[s for s in data['layerStyles'] if 'liquid glass' in (s.get('name') or '').lower()]
    if lg:
      for s in lg: lines.append(f'- `{s["name"]}` (`{s["sourceId"]}`)')
    else: lines.append('- No shared layer style name contains `Liquid Glass`; inspect component styles by source ID.')
    return lines

def main():
    ap=argparse.ArgumentParser(); ap.add_argument('--ios-sketch',type=Path); ap.add_argument('--macos-sketch',type=Path); ap.add_argument('--macos-assets',type=Path); ap.add_argument('--reuse-assets-from',type=Path); ap.add_argument('--output',type=Path,required=True); ap.add_argument('--component-map',type=Path,required=True); a=ap.parse_args()
    if (a.macos_assets is None)==(a.reuse_assets_from is None): ap.error('pass exactly one of --macos-assets or --reuse-assets-from')
    ios=SourceFile(a.ios_sketch,'839ecf260025264db9000a4ce23ef2804c33c8d62642a6373ed310858ca64171'); mac=SourceFile(a.macos_sketch,'f5aa2f4f319eae66b5eab0bbc0faacb10ce16656457cff528f9810d57ff1354d')
    if a.reuse_assets_from is not None: macos_assets=json.loads(a.reuse_assets_from.read_text())['macosAssets']
    else: macos_assets=extract_asset_bundle(SourceFile(a.macos_assets,'4bbbb036ce008f2213803ad05d7591ed4c0ac009f677a2e1d3d3b315ceb1ce31'))
    data={'schemaVersion':1,'ios':extract_sketch_reference(ios),'macos':extract_sketch_reference(mac),'macosAssets':macos_assets}
    write_deterministic_json(data,a.output)
    lines=['# Generated Apple UI Kit Component Map','', '> Generated deterministically from the source-locked Sketch files. Do not edit by hand.','']+_component_map('iOS 27',data['ios'])+['']+_component_map('macOS 27',data['macos'])+['']
    a.component_map.parent.mkdir(parents=True,exist_ok=True); a.component_map.write_text('\n'.join(lines))
    print('APPLE_UI_KIT_REFERENCE_EXTRACTION=PASS'); print('IOS_PAGES',data['ios']['pageCount']); print('MACOS_PAGES',data['macos']['pageCount']); print('IOS_LAYERS',len(data['ios']['componentLayers'])); print('MACOS_LAYERS',len(data['macos']['componentLayers']))
if __name__=='__main__': main()
