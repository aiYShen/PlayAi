package com.aiyun.playai.config;

import java.nio.charset.StandardCharsets;
import java.sql.DriverManager;
import java.sql.SQLException;
import java.util.Properties;
import javax.sql.DataSource;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.core.io.ClassPathResource;

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
    try {
      // 加载 resources 下的 calcite-model.json 文件
      ClassPathResource resource = new ClassPathResource("model.json");

      // 使用 Scanner 或 JDK 21+ 的 Files.readString() 快速读取
      return resource.getContentAsString(StandardCharsets.UTF_8);
    } catch (Exception e) {
      throw new RuntimeException("无法加载 Calcite 模型文件，请检查 resources 路径", e);
    }
  }
}
