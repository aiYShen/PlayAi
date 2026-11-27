package com.aiyun.playai.controller;

import com.aiyun.playai.controller.entity.User;
import com.aiyun.playai.controller.service.UserService;
import com.aiyun.playai.controller.serviceImpl.UserServiceImpl;
import com.baomidou.mybatisplus.core.conditions.query.QueryWrapper;
import java.util.List;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

/** User class. */
@RestController
@RequestMapping("/user")
public class UserController {

  @Autowired
  private UserServiceImpl userServiceImpl;

  @GetMapping("/queryAllPg")
  public List<User> queryAllPg(){
    return userServiceImpl.queryAllPg();
  }

  @GetMapping("/queryAllCk")
  public List<User> queryAllCk(){
    return userServiceImpl.queryAllCk();
  }
}
