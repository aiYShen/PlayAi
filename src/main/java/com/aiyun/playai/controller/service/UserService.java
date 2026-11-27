package com.aiyun.playai.controller.service;

import com.aiyun.playai.controller.entity.User;
import com.baomidou.mybatisplus.spring.service.IService;
import java.util.List;

/** 业务层接口 UserService interface. */
public interface UserService extends IService<User> {

  default List<User> queryAll() {
      return list();
  };
}
