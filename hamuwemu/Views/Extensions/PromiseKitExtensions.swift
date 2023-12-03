//
//  PromiseKitExtensions.swift
//  hamuwemu
//
//  Created by Dulitha Dabare on 2022-04-18.
//

import PromiseKit

extension Promise {
    func timeout(seconds: TimeInterval) -> Promise<T> {
        let pending = Promise<T>.pending()
        after(seconds: seconds).done {
            pending.resolver.reject(PromiseError.timeout)
        }
        pipe(to: pending.resolver.resolve)
        return pending.promise
    }
}
