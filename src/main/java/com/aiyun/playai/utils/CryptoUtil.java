package com.aiyun.playai.utils;

import com.baomidou.dynamic.datasource.toolkit.CryptoUtils;

/** CryptoUtil class. */
public class CryptoUtil {

  public static void main(String[] args) throws Exception {
    // 生成密钥对：arr[0] = 私钥，arr[1] = 公钥
    String[] arr = CryptoUtils.genKeyPair(512);

    System.out.println("privateKey: " + arr[0]);   // 只留在生成端，不要进配置
    System.out.println("publicKey:  " + arr[1]);   // 填到 public-key

    // 用【私钥】加密
    // System.out.println("url: " + CryptoUtils.encrypt(arr[0], "jdbc:mysql://127.0.0.1:3306/order"));
    System.out.println("username: " + CryptoUtils.encrypt(arr[0], ""));
    System.out.println("password: " + CryptoUtils.encrypt(arr[0], ""));
  }
}
