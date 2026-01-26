package com.aiyun.playai.config;

import java.sql.DriverManager;
import java.sql.SQLException;
import java.util.Properties;
import javax.sql.DataSource;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

/** CalciteDataSourceConfig class. */
@Configuration
public class CalciteDataSourceConfig {
  @Bean(name = "calciteDataSource")
  public DataSource calciteDataSource() throws SQLException {
    Properties config = new Properties();
    // 指定模型文件路径
    config.setProperty("model", "inline:" + loadModelJson());
    config.setProperty("caseSensitive", "false");

    // 创建连接并返回 DataSource
    return DriverManager.getConnection("jdbc:calcite:", config).unwrap(DataSource.class);
  }

  private String loadModelJson() {
    // 2026 年推荐做法：从 Resource 或配置中心动态读取 JSON 字符串
    return "{...}";
  }
}
