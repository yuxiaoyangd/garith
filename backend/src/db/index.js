const Database = require('better-sqlite3');
const path = require('path');
const fs = require('fs');

// 确保数据库目录存在
const dbDir = path.join(__dirname, '../../../data');
if (!fs.existsSync(dbDir)) {
    fs.mkdirSync(dbDir, { recursive: true });
}

const dbPath = path.join(dbDir, 'garith.db');

// 创建数据库连接
const db = new Database(dbPath);

// 启用 WAL 模式
db.pragma('journal_mode = WAL');
db.pragma('foreign_keys = ON');

// 读取并执行 schema
const schema = fs.readFileSync(path.join(__dirname, 'schema.sql'), 'utf8');
db.exec(schema);

console.log('Database initialized and connected');

module.exports = db;
