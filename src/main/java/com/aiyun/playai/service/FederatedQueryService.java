package com.aiyun.playai.service;

import java.util.List;
import java.util.Map;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Service;

/** FederatedQueryService class. */
@Service
public class FederatedQueryService {

  @Autowired
  private JdbcTemplate jdbcTemplate;

  public List<Map<String, Object>> getMixedData() {
    // 跨 MySQL 表和 CSV 文件的联邦查询
    String sql = "SELECT u.username, r.amount " +
        "FROM MYSQL_DATA.users u " +
        "JOIN LOCAL_FILES.monthly_report r ON u.id = r.user_id " +
        "WHERE r.status = 'PAID'";
    return jdbcTemplate.queryForList(sql);
  }
}
