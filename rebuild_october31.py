#!/usr/bin/env python3
"""Reconstruct October 31 directly from stock 368.81 and pinned vendor modules.

Offline patch application only: no driver installation or vendor code execution.
"""
import argparse,datetime,hashlib,json,re,shutil
from pathlib import Path
from rebuild import check,child,firmware,inventory,repack,require,run7z

def main():
    here=Path(__file__).resolve().parent
    data_root=here/'sources/october31'
    m=json.loads((data_root/'stock-manifest.json').read_text())
    ap=argparse.ArgumentParser(description=__doc__)
    for key in m['inputs']:
        ap.add_argument('--'+key,type=Path,required=True,help='Exact stock installer'if key=='stock'else'Expanded donor nvlddmkm.sys; see REBUILDING.md')
    ap.add_argument('--out',type=Path,required=True)
    ap.add_argument('--sevenzip',default='7z')
    args=ap.parse_args()
    inputs={k:check(getattr(args,k).read_bytes(),h,k)for k,h in m['inputs'].items()}
    require(shutil.which(args.sevenzip)is not None,'7-Zip not found')
    root=args.out.resolve();require(not root.exists(),'Output directory already exists')
    root.mkdir(parents=True);work=root/'work';work.mkdir()
    stock=work/'stock';stock_cpl=work/'stock-cpl'
    run7z(args.sevenzip,['x','-y','-o'+str(stock),str(args.stock.resolve())],work/'extract-stock.log')
    require(inventory(stock)==m['stock_package'],'Stock package inventory differs')
    run7z(args.sevenzip,['x','-y','-o'+str(stock_cpl),str(stock/'Display.Driver/NvCplSetupInt.exe')],work/'extract-stock-cpl.log')
    require(inventory(stock_cpl)==m['stock_cpl'],'Stock Control Panel inventory differs')
    package=root/'Forceware 382.69';cpl=work/'cpl';package.mkdir();cpl.mkdir();expanded={}
    for r in m['files']:
        require(r['tree']in ['package','cpl'],'Unknown tree')
        target=child(package if r['tree']=='package'else cpl,r['path'])
        if r['kind']=='generated':continue
        source=b''
        if r.get('source'):
            source_root=stock if r['tree']=='package'else stock_cpl
            src=child(source_root,r['source'])
            if r.get('expand'):
                key=(r['tree'],r['source'])
                if key not in expanded:
                    folder=work/('expand-'+str(len(expanded)))
                    run7z(args.sevenzip,['x','-y','-o'+str(folder),str(src)],work/(folder.name+'.log'))
                    members=[p for p in folder.rglob('*')if p.is_file()]
                    require(len(members)==1,'Expected a single compressed member')
                    expanded[key]=members[0].read_bytes()
                source=expanded[key]
            else:source=src.read_bytes()
            check(source,r['source_sha256'],r['path']+' source')
        if r['kind']=='copy':result=source
        elif r['kind']=='template':result=child(data_root/'templates',r['template']).read_bytes()
        else:
            require(r['kind']=='patch','Unknown record kind')
            result=bytearray(source[:r['size']]);result.extend(bytes(r['size']-len(result)))
            for f in r.get('firmware',[]):
                b=firmware(inputs[f['donor']],f);off=f['target_offset']
                require(0<=off and off+len(b)<=len(result),'Firmware output bounds')
                result[off:off+len(b)]=b
            for c in r.get('copies',[]):
                src=c['source_offset'];off=c['target_offset'];size=c['size']
                require(0<=src and size>0 and src+size<=len(source)and 0<=off and off+size<=len(result),'Stock-copy bounds')
                b=check(source[src:src+size],c['sha256'],'Stock-copy range')
                result[off:off+size]=b
            for e in r['edits']:
                off=e['offset'];before=bytes.fromhex(e['before']);after=bytes.fromhex(e['after'])
                require(0<=off and len(before)==len(after)and off+len(before)<=len(result),'Patch bounds')
                require(result[off:off+len(before)]==before,'Patch byte guard: '+r['path'])
                result[off:off+len(before)]=after
        require(len(result)==r['size'],'Output size differs: '+r['path'])
        check(result,r['sha256'],r['path']);target.parent.mkdir(parents=True,exist_ok=True);target.write_bytes(result)
    require(inventory(cpl)==m['final_cpl'],'Final Control Panel payload differs')
    date=datetime.datetime.strptime(m['build_date'],'%m/%d/%Y').date()
    repack(args.sevenzip,(stock/'Display.Driver/NvCplSetupInt.exe').read_bytes(),cpl,package/'Display.Driver/NvCplSetupInt.exe',work/'cpl.7z',work/'pack-cpl.log',build_date=date)
    (package/'SHA256SUMS.txt').write_text(''.join(h+'  '+n+'\n'for n,h in sorted(inventory(package).items())))
    actual=inventory(package);generated={'Display.Driver/NvCplSetupInt.exe','SHA256SUMS.txt'}
    require(set(actual)==set(m['final_package']),'Unexpected package members')
    require(all(actual[n]==h for n,h in m['final_package'].items()if n not in generated),'Final runtime payload differs')
    original=inputs['stock'];start=original.index(b';!@Install@!');end=original.index(b"7z\xbc\xaf\x27\x1c",start)
    config=original[start:end].decode('utf8')
    config=config.replace('DisplayDriver\\\\368.81\\\\WinXP\\\\International','Forceware 382.69')
    config=config.replace('NVIDIA Display Driver v368.81 - International Package','Forceware 382.69').replace('NVIDIA Display Driver v368.81 - International','Forceware 382.69')
    launcher=original[:start]+config.encode('utf8')+original[end:]
    exe=root/(m['release_title']+'.exe')
    repack(args.sevenzip,launcher,package,exe,work/'package.7z',work/'pack.log',outer=True,release_title=m['release_title'],build_date=date)
    run7z(args.sevenzip,['x','-y','-o'+str(work/'package-check'),str(exe)],work/'check-package.log')
    run7z(args.sevenzip,['x','-y','-o'+str(work/'cpl-check'),str(package/'Display.Driver/NvCplSetupInt.exe')],work/'check-cpl.log')
    require(inventory(work/'package-check')==actual,'Final EXE extraction differs')
    require(inventory(work/'cpl-check')==m['final_cpl'],'Final nested extraction differs')
    output_hash=hashlib.sha256(exe.read_bytes()).hexdigest()
    result=dict(base='stock 368.81',prior_forceware_installer_required=False,input_hashes=m['inputs'],runtime_payload_exact=True,non_generated_package_files=len(actual)-2,control_panel_files=len(m['final_cpl']),donor_resources=sum(len(r.get('firmware',[]))for r in m['files']),installer_sha256=output_hash,release_installer_sha256=m['release_installer_sha256'],installer_exact=output_hash==m['release_installer_sha256'],all_extraction_checks_pass=True)
    (root/'rebuild-result.json').write_text(json.dumps(result,indent=2)+'\n');print(json.dumps(result,indent=2))

if __name__=='__main__':main()
