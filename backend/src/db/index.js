const Database = require('better-sqlite3');
const path = require('path');
const fs = require('fs');

// 确保数据库目录存在
const dbDir = path.join(__dirname, '../../data');
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

function ensureColumn(table, column, definition) {
    const columns = db.prepare(`PRAGMA table_info(${table})`).all().map((col) => col.name);
    if (!columns.includes(column)) {
        db.exec(`ALTER TABLE ${table} ADD COLUMN ${column} ${definition}`);
        console.log(`Added missing column ${table}.${column}`);
    }
}

ensureColumn('users', 'avatar_url', 'TEXT');
ensureColumn('users', 'bio', 'TEXT');
ensureColumn('projects', 'images', 'TEXT');

module.exports = db;
