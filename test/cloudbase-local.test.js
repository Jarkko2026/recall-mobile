// test/cloudbase-local.test.js
// 本地化测试 CloudBase 云函数（不依赖真实环境）
// 通过 mock auth.getUserInfo 实现

const path = require('path');
const Module = require('module');

// Mock @cloudbase/node-sdk
const originalResolve = Module._resolveFilename;
Module._resolveFilename = function(request, parent, ...rest) {
  if (request === '@cloudbase/node-sdk') {
    return path.join(__dirname, 'mocks', 'cloudbase-mock.js');
  }
  return originalResolve.call(this, request, parent, ...rest);
};

const itemsApi = require('../cloudbase/functions/items-api');
const userApi = require('../cloudbase/functions/user-api');
const searchApi = require('../cloudbase/functions/search-api');

async function run() {
  const evt = (method, path, body = null, query = null) => ({
    method, path,
    body: body ? JSON.stringify(body) : null,
    queryStringParameters: query,
    userInfo: { openId: 'test_openid_abc123' },
  });

  // 1. 创建 item
  const r1 = await itemsApi.main(evt('POST', '/items', { title: '测试文章', content: '内容', type: 'link' }));
  assertEq(r1.code, 0, 'create ok');
  assert(r1.data.item.id.startsWith('i_'), 'has id');
  const itemId = r1.data.item.id;
  console.log('✓ 创建 item:', itemId);

  // 2. 列表
  const r2 = await itemsApi.main(evt('GET', '/items', null, { limit: '10' }));
  assertEq(r2.code, 0, 'list ok');
  console.log('✓ 列表返回', r2.data.items.length, '条');

  // 3. 详情
  const r3 = await itemsApi.main(evt('GET', `/items/${itemId}`));
  assertEq(r3.code, 0, 'get ok');
  console.log('✓ 详情 ok');

  // 4. 回看
  const r4 = await itemsApi.main(evt('POST', `/items/${itemId}/view`));
  assertEq(r4.code, 0, 'view ok');
  console.log('✓ 回看事件已记录');

  // 5. 删除
  const r5 = await itemsApi.main(evt('DELETE', `/items/${itemId}`));
  assertEq(r5.code, 0, 'delete ok');
  console.log('✓ 已删除');

  // 6. user-api: get me
  const r6 = await userApi.main(evt('GET', '/users/me'));
  assertEq(r6.code, 0, 'me ok');
  console.log('✓ user me ok');

  // 7. user-api: get key status (未配置)
  const r7 = await userApi.main(evt('GET', '/api-keys/me'));
  assertEq(r7.code, 0, 'key status ok');
  assertEq(r7.data.configured, false, 'no key yet');
  console.log('✓ key 状态查询 ok');

  // 8. search
  const r8 = await searchApi.main(evt('GET', '/search', null, { q: 'xx' }));
  assertEq(r8.code, 0, 'search ok');
  console.log('✓ search ok');

  console.log('\n✅ 所有 8 个云函数端到端测试通过');
}

function assert(cond, msg) {
  if (!cond) {
    console.error('  ✗ ' + msg);
    process.exit(1);
  }
}

function assertEq(a, b, msg) {
  if (a !== b) {
    console.error(`  ✗ ${msg}: expected ${b}, got ${a}`);
    process.exit(1);
  }
}

run().catch((e) => { console.error('TEST FAILED:', e); process.exit(1); });
