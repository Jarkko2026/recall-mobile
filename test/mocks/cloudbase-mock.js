// test/mocks/cloudbase-mock.js
// 内存版 CloudBase 模拟器 —— 仅供本地测试云函数逻辑

class MockCollection {
  constructor(name) {
    this.name = name;
    this.docs = new Map();
    this._idCounter = 0;
  }
  _nextId() {
    return `${this.name}_${Date.now().toString(36)}${(this._idCounter++).toString(36)}`;
  }
  // 简单 where 实现
  where(filter) {
    const matched = [];
    for (const d of this.docs.values()) {
      if (matchesFilter(d, filter)) matched.push(d);
    }
    return this._query(matched);
  }
  _query(docs) {
    const q = {
      _docs: docs,
      limit: () => ({ get: async () => ({ data: q._docs }) }),
      orderBy: (field, dir) => {
        q._docs.sort((a, b) => {
          const av = a[field] || 0, bv = b[field] || 0;
          return dir === 'desc' ? bv - av : av - bv;
        });
        return q;
      },
      get: async () => ({ data: q._docs }),
      update: async (patch) => {
        for (const d of q._docs) Object.assign(d, patch);
      },
      remove: async () => {
        for (const d of q._docs) this.docs.delete(d._id);
      },
    };
    return q;
  }
  doc(id) {
    const d = this.docs.get(id);
    return {
      get: async () => ({ data: d ? [d] : [] }),
      update: async (patch) => { if (d) Object.assign(d, patch); },
    };
  }
  add(doc) {
    if (!doc._id) doc._id = this._nextId();
    this.docs.set(doc._id, doc);
    return { id: doc._id };
  }
  createIndex() { return Promise.resolve({ ok: true }); }
  createCollection(name) { return Promise.resolve({ ok: true }); }
}

function matchesFilter(doc, filter) {
  for (const [k, v] of Object.entries(filter)) {
    if (typeof v === 'object' && v !== null && v.constructor && v.constructor.name === 'IncCommand') {
      // _.inc(1) - skip
      continue;
    }
    if (Array.isArray(v) && v.length === 1 && typeof v[0] === 'string') {
      // tag_ids in [...] mock: 简化处理
      if (!doc[k] || !doc[k].some((x) => v.includes(x))) return false;
      continue;
    }
    if (doc[k] !== v) return false;
  }
  return true;
}

const collections = {
  users: new MockCollection('users'),
  items: new MockCollection('items'),
  tags: new MockCollection('tags'),
  categories: new MockCollection('categories'),
  summaries: new MockCollection('summaries'),
  attachments: new MockCollection('attachments'),
  api_keys: new MockCollection('api_keys'),
  quotas: new MockCollection('quotas'),
  activity_log: new MockCollection('activity_log'),
};

module.exports = {
  init: () => ({
    auth: () => ({
      getUserInfo: async () => ({ openId: 'test_openid_abc123' }),
    }),
    database: () => ({
      collection: (name) => collections[name] || (collections[name] = new MockCollection(name)),
      command: {
        inc: (n) => ({ _inc: n, constructor: { name: 'IncCommand' } }),
      },
    }),
  }),
};
