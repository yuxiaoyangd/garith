const { authenticateToken } = require('../middleware/auth');

// 获取用户通知列表
async function getNotifications(request, reply) {
    const user = request.user;
    const { page = 1, limit = 20, unread_only = false } = request.query;
    
    let query = `
        SELECT n.*, u.nickname as from_user_nickname
        FROM notifications n
        LEFT JOIN users u ON n.from_user_id = u.id
        WHERE n.to_user_id = ?
    `;
    const params = [user.id];
    
    if (unread_only === 'true') {
        query += ' AND n.is_read = 0';
    }
    
    query += ' ORDER BY n.created_at DESC';
    
    // 分页
    const offset = (parseInt(page) - 1) * parseInt(limit);
    query += ' LIMIT ? OFFSET ?';
    params.push(parseInt(limit), offset);
    
    const notifications = request.server.db.prepare(query).all(...params);
    
    return reply.send(notifications);
}

// 获取未读通知数量
async function getUnreadCount(request, reply) {
    const user = request.user;
    
    const count = request.server.db.prepare(`
        SELECT COUNT(*) as count FROM notifications 
        WHERE to_user_id = ? AND is_read = 0
    `).get(user.id);
    
    return reply.send({ count: count.count });
}

// 标记通知为已读
async function markAsRead(request, reply) {
    const user = request.user;
    const { id } = request.params;
    
    const result = request.server.db.prepare(`
        UPDATE notifications 
        SET is_read = 1, read_at = datetime('now')
        WHERE id = ? AND to_user_id = ?
    `).run(id, user.id);
    
    if (result.changes === 0) {
        return reply.code(404).send({ error: 'Notification not found' });
    }
    
    return reply.send({ message: 'Notification marked as read' });
}

// 标记所有通知为已读
async function markAllAsRead(request, reply) {
    const user = request.user;
    
    request.server.db.prepare(`
        UPDATE notifications 
        SET is_read = 1, read_at = datetime('now')
        WHERE to_user_id = ? AND is_read = 0
    `).run(user.id);
    
    return reply.send({ message: 'All notifications marked as read' });
}

// 创建通知（内部使用）
function createNotification(db, { to_user_id, from_user_id, type, title, content, related_id }) {
    return db.prepare(`
        INSERT INTO notifications (to_user_id, from_user_id, type, title, content, related_id)
        VALUES (?, ?, ?, ?, ?, ?)
    `).run(to_user_id, from_user_id || null, type, title, content, related_id || null);
}

module.exports = {
    getNotifications,
    getUnreadCount,
    markAsRead,
    markAllAsRead,
    createNotification
};
