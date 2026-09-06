import '../test-support/loader.mjs';
import { test } from 'node:test';
import assert from 'node:assert/strict';
const { default: browser, CdpClient } = await import('./index.ts');

test('fresh task tabs preserve existing tabs, stay selected and close only owned tabs', async () => {
  const tools = new Map();
  browser({registerTool:t=>tools.set(t.name,t),registerCommand(){},on(){}});
  const original = CdpClient.connect;
  const targets = [{targetId:'user',url:'https://example.org',title:'User tab'}];
  const touched = [];
  let next = 0;
  const client = {
    isClosed:false, listTargets:async()=>targets.slice(), attach:async id=>id, isolatedWorld:async id=>id,
    send:async(method, params, session)=>{
      if(method === 'Target.createTarget') {const targetId = `task${++next}`;targets.unshift({targetId,url:params.url});return {targetId};}
      if(method === 'Target.closeTarget') {touched.push(params.targetId);targets.splice(targets.findIndex(t=>t.targetId===params.targetId),1);return {success:true};}
      if(method === 'Runtime.evaluate') {
        if(params.expression.includes('return closeTab();'))return {result:{value:{__piBrowserCommand:'closeTab'}}};
        if(!params.expression.startsWith('(async'))return {result:{value:{text:'snapshot',refCount:0,nodeCount:0}}};
        return {result:{type:'string',value:session}};
      }
      throw new Error(method);
    },
  };
  CdpClient.connect = async()=>client;
  const execute = tools.get('browser_execute').execute;
  try {
    await assert.rejects(execute('bad',{newTab:true,tab:0,code:'return 1;'}),/cannot be combined/);
    assert.equal(next,0);
    assert.equal((await execute('new',{newTab:true,code:'return 1;'})).content[0].text,'task1');
    assert.equal((await execute('same',{code:'return 1;'})).content[0].text,'task1');
    assert.equal((await execute('other',{newTab:true,code:'return 1;'})).content[0].text,'task2');
    assert.equal(targets.length,3);
    await execute('close',{code:'return closeTab();'});
    assert.deepEqual(touched,['task2']);
    await tools.get('browser_snapshot').execute('snapshot',{});
    await assert.rejects(execute('user',{tab:1,code:'return closeTab();'}),/Refusing to close/);
    assert.equal(targets.find(t=>t.targetId==='user').url,'https://example.org');
    assert.equal(targets.length,2);
  } finally {CdpClient.connect = original;}
});
