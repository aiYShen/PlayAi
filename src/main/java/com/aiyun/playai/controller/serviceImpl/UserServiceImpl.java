package com.aiyun.playai.controller.serviceImpl;

import com.aiyun.playai.controller.entity.User;
import com.aiyun.playai.controller.mapper.UserMapper;
import com.aiyun.playai.controller.service.UserService;
import com.baomidou.dynamic.datasource.annotation.DS;
import com.baomidou.mybatisplus.spring.service.impl.ServiceImpl;
import java.util.List;
import org.springframework.stereotype.Service;

/** 业务实现层 UserServiceImpl class. */
@Service
@DS("pgsql")
public class UserServiceImpl extends ServiceImpl<UserMapper, User> implements UserService {

  @DS("clickhouse")
  public List<User> queryAllCk() {
    return queryAll();
  }

  public List<User> queryAllPg() {
    return queryAll();
  }
}
