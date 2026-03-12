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

    org.apache.commons.dbcp2.BasicDataSource dataSource = new org.apache.commons.dbcp2.BasicDataSource();
    dataSource.setDriverClassName("org.apache.calcite.jdbc.Driver");
    dataSource.setUrl("jdbc:calcite:");
    dataSource.setConnectionProperties("model=src/main/resources/model.json"); // 传入配置

    return dataSource;

  }

}
