require('dotenv').config();
const fastify = require('fastify')({ logger: true });

// 注册插件
fastify.register(require('@fastify/cors'), {
    origin: true, // 允许所有来源，生产环境需要限制
    credentials: true
});

// 注册JWT插件
fastify.register(require('@fastify/jwt'), {
    secret: process.env.JWT_SECRET || 'your-secret-key-change-in-production'
});

// 数据库连接
const db = require('./db');

// 将数据库连接挂载到fastify实例
fastify.decorate('db', db);

// 注册路由
fastify.register(require('./routes/auth'), { prefix: '/auth' });
fastify.register(require('./routes/projects'), { prefix: '/projects' });
fastify.register(require('./routes/progress'), { prefix: '/progress' });
fastify.register(require('./routes/intents'), { prefix: '/intents' });
fastify.register(require('./routes/me'), { prefix: '/me' });

// 健康检查
fastify.get('/health', async (request, reply) => {
    return { status: 'ok', timestamp: new Date().toISOString() };
});

// 错误处理
fastify.setErrorHandler((error, request, reply) => {
    request.log.error(error);
    
    if (error.validation) {
        reply.code(400).send({
            error: 'Validation Error',
            details: error.validation
        });
        return;
    }
    
    reply.code(500).send({
        error: 'Internal Server Error',
        message: process.env.NODE_ENV === 'development' ? error.message : 'Something went wrong'
    });
});

// 启动服务器
const start = async () => {
    try {
        const port = process.env.PORT || 3000;
        await fastify.listen({ port, host: '0.0.0.0' });
        console.log(`Server running on port ${port}`);
    } catch (err) {
        fastify.log.error(err);
        process.exit(1);
    }
};

start();
