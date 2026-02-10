class AppConstants {
  static const Map<String, List<String>> projectFieldsGrouped = {
    '互联网': ['Web应用', '移动App', '小程序', '桌面应用', '游戏'],
    '前沿科技': ['人工智能(AI)', '物联网(IoT)', '区块链', 'VR/AR', '元宇宙'],
    '行业应用': ['企业服务', '电商', '教育', '金融', '医疗', '社交'],
    '其他': ['硬件开发', '嵌入式', '其他'],
  };

  static const Map<String, List<String>> abilityFieldsGrouped = {
    '技术研发': ['前端开发', '后端开发', '全栈开发', '移动开发', 'AI/算法', '测试/QA', '运维/DevOps', '架构师', '数据分析'],
    '产品设计': ['产品经理', 'UI/UX设计', '视觉设计', '用户研究', '游戏策划'],
    '运营市场': ['新媒体运营', '市场推广', '内容创作', 'SEO/ASO', '增长黑客'],
    '其他': ['项目管理', '投资/融资', '法律咨询', '人力资源', '其他'],
  };

  static const List<String> projectTypes = ['求资', '合伙', '外包'];
  static const List<String> stages = ['想法', '原型', '开发中', '已上线'];
  
  // Helpers to get flat lists
  static List<String> get projectFieldsFlat {
    List<String> items = [];
    projectFieldsGrouped.values.forEach(items.addAll);
    return items;
  }
  
  static List<String> get abilityFieldsFlat {
    List<String> items = [];
    abilityFieldsGrouped.values.forEach(items.addAll);
    return items;
  }
}
