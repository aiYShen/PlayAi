package com.aiyun.playai;

import com.alibaba.druid.spring.boot4.autoconfigure.DruidDataSourceAutoConfigure;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;

@SpringBootApplication(exclude = DruidDataSourceAutoConfigure.class)
public class PlayAiApplication {

  public static void main(String[] args) {
    SpringApplication.run(PlayAiApplication.class, args);
  }
}
