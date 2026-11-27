package com.aiyun.playai.controller.mapper;

import com.aiyun.playai.controller.entity.User;
import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import org.apache.ibatis.annotations.Mapper;

/** 数据访问层 UserMapper class. */
@Mapper
public interface UserMapper extends BaseMapper<User> {}
