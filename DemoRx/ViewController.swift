//
//  ViewController.swift
//  DemoRx
//
//  Created by Xavier De Koninck on 11/01/2017.
//  Copyright © 2017 XavierDeKoninck. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

enum MyError: Error {
  case nilValues
}

class ViewController: UIViewController, UITextFieldDelegate {
  
  @IBOutlet weak var textField: UITextField!
  @IBOutlet weak var button: UIButton!
  @IBOutlet weak var movingView: UIView!
  
  let queue = SerialDispatchQueueScheduler(internalSerialQueueName: "DemoQueue")
  
  let disposeBag = DisposeBag()
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    textField.rx.text
      .asObservable()
      .debug()
      .observeOn(queue)
      .flatMapLatest(newLocation)
      .debug()
      .shareReplay(1)
      .map({ location in
        return location.0 != nil && location.1 != nil
      })
      .observeOn(MainScheduler.instance)
      .subscribe(onNext: { [weak self] isValid in
        
        if isValid {
          self?.button.backgroundColor = UIColor.blue
          self?.button.isEnabled = true
        }
        else {
          self?.button.backgroundColor = UIColor.gray
          self?.button.isEnabled = false
        }
      })
      .addDisposableTo(disposeBag)
    
    button.rx.tap
      .asObservable()
      .debug()
      .observeOn(queue)
      .map { [weak self] in
        self?.textField.text
      }
      .flatMap(newLocation)
      .shareReplay(1)
      .flatMap(location)
      .observeOn(MainScheduler.instance)
      .subscribe(onNext: { [weak self] value in
        self?.movingView.frame.origin.x = CGFloat(value.0)
        self?.movingView.frame.origin.y = CGFloat(value.1)
      })
      .addDisposableTo(disposeBag)
  }
  
  func location(location: (Float?, Float?)) -> Observable<(Float, Float)> {
    
    return Observable.create { observer in
      
      if let x = location.0,
        let y = location.1 {
        
        let res: (Float, Float) = (x, y)
        
        observer.on(.next(res))
        observer.on(.completed)
      }
      observer.on(.error(MyError.nilValues))
      
      return Disposables.create()
    }
  }
  
  func newLocation(text: String?) -> Observable<(Float?, Float?)> {
    
    return Observable.create { observer in
      
      let positions = text?.components(separatedBy: ",")
      if let positions = positions,
        positions.count == 2 {
        let x = Float(positions[0])
        let y = Float(positions[1])
        
        if let x = x,
          let y = y {
          
          let res: (Float?, Float?) = (x, y)
          observer.on(.next(res))
          observer.on(.completed)
        }
      }
      
      let res: (Float?, Float?) = (nil, nil)
      observer.on(.next(res))
      observer.on(.completed)
      
      return Disposables.create()
    }
  }
  
  //  @IBAction func buttonPressed() {
  //
  //    let text = textField.text
  //    let positions = text?.components(separatedBy: ",")
  //    if let positions = positions,
  //      positions.count == 2 {
  //      let x = Float(positions[0])
  //      let y = Float(positions[1])
  //
  //      if let x = x,
  //        let y = y {
  //
  //          movingView.frame.origin.x = CGFloat(x)
  //          movingView.frame.origin.y = CGFloat(y)
  //      }
  //    }
  //  }
  //
  //  func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
  //
  //    let str = (textField.text as NSString?)
  //
  //    let positions = str?
  //      .replacingCharacters(in: range, with: string)
  //      .components(separatedBy: ",")
  //
  //    if let positions = positions,
  //      positions.count == 2 {
  //      let x = Float(positions[0])
  //      let y = Float(positions[1])
  //
  //      if let _ = x,
  //        let _ = y {
  //          button.backgroundColor = UIColor.blue
  //          button.isEnabled = true
  //        return true
  //      }
  //    }
  //    button.backgroundColor = UIColor.gray
  //    button.isEnabled = false
  //    return true
  //  }
}

