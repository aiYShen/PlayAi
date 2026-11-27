package com.aiyun.playai.config;

import com.baomidou.dynamic.datasource.toolkit.DynamicDataSourceContextHolder;
import com.baomidou.mybatisplus.extension.plugins.MybatisPlusInterceptor;
import com.baomidou.mybatisplus.extension.plugins.inner.DynamicTableNameInnerInterceptor;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

/** MybatisPlusConfig class. */
@Configuration
public class MybatisPlusConfig {

  @Bean
  public MybatisPlusInterceptor mybatisPlusInterceptor() {

    MybatisPlusInterceptor interceptor =
        new MybatisPlusInterceptor();

    DynamicTableNameInnerInterceptor dynamicTableInterceptor =
        new DynamicTableNameInnerInterceptor(
            (sql, tableName) -> {

              // 获取当前实际切换的数据源名称
              String dataSourceKey =
                  DynamicDataSourceContextHolder.peek();

              // 仅 PostgreSQL 添加 public.
              if (!"pgsql".equals(dataSourceKey)) {
                return tableName;
              }

              // 已经包含 Schema，不重复添加
              if (tableName.contains(".")) {
                return tableName;
              }

              return "public." + tableName;
            }
        );

    interceptor.addInnerInterceptor(dynamicTableInterceptor);

    return interceptor;
  }
}
