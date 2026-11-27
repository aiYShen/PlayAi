package com.aiyun.playai.controller.entity;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import java.time.LocalDate;
import java.time.OffsetDateTime;
import lombok.Data;

/** User class. */
@Data
@TableName(value = "user", autoResultMap = true)
public class User {

  /**
   * 主键，数据库自动生成
   */
  @TableId(type = IdType.AUTO)
  private Long id;

  /**
   * 姓名
   */
  private String name;

  /**
   * 身份证号码
   */
  private String cardNum;

  /**
   * 性别
   */
  private String sex;

  /**
   * 年龄
   */
  private Integer age;

  /**
   * 地址
   */
  private String address;

  /**
   * 出生日期
   */
  private LocalDate birthday;

  /**
   * 手机号码
   */
  private String phone;

  /**
   * 电子邮箱
   */
  private String email;

  /**
   * 关键词
   */
  private String keywords;

  /**
   * 个人资料，PostgreSQL JSONB
   */
  private String profile;

  /**
   * 创建时间，PostgreSQL TIMESTAMPTZ
   */
  private OffsetDateTime createTime;
}
