//
//  VietnameseNumberConverter.swift
//  voice-ott-test
//
//  Created by Le Viet Anh on 25/2/25.
//

import Foundation

class VietnameseNumberConverter {
    // Mảng đơn vị
    private let units = ["", "một", "hai", "ba", "bốn", "năm", "sáu", "bảy", "tám", "chín"]
    
    // Mảng đơn vị hàng chục
    private let tens = ["", "mười", "hai mươi", "ba mươi", "bốn mươi", "năm mươi", "sáu mươi", "bảy mươi", "tám mươi", "chín mươi"]
    
    // Mảng đơn vị hàng
    private let scales = ["", "nghìn", "triệu", "tỷ", "nghìn tỷ", "triệu tỷ"]
    
    // Hàm chuyển đổi chính
    func convert(number: Int) -> String {
        if number == 0 {
            return "không"
        }
        
        var result = ""
        var num = number
        var scaleIndex = 0
        
        while num > 0 {
            let threeDigits = num % 1000
            if threeDigits > 0 {
                let threeDigitsText = convertLessThanOneThousand(threeDigits)
                result = threeDigitsText + " " + scales[scaleIndex] + " " + result
            }
            
            scaleIndex += 1
            num /= 1000
        }
        
        return result.trimmingCharacters(in: .whitespaces)
    }
    
    // Hàm chuyển đổi cho số dưới 1000
    private func convertLessThanOneThousand(_ number: Int) -> String {
        var result = ""
        
        // Xử lý hàng trăm
        let hundreds = number / 100
        if hundreds > 0 {
            result += units[hundreds] + " trăm "
        }
        
        // Xử lý hàng chục và đơn vị
        let tensAndUnits = number % 100
        
        if tensAndUnits > 0 {
            // Trường hợp đặc biệt khi hàng trăm có giá trị và hàng chục bằng 0
            if hundreds > 0 && tensAndUnits < 10 {
                result += "lẻ "
            }
            
            if tensAndUnits < 10 {
                result += units[tensAndUnits]
            } else if tensAndUnits < 20 {
                result += "mười "
                
                let unitDigit = tensAndUnits % 10
                if unitDigit > 0 {
                    if unitDigit == 5 {
                        result += "lăm"
                    } else if unitDigit == 1 {
                        result += "một"
                    } else {
                        result += units[unitDigit]
                    }
                }
            } else {
                let tensDigit = tensAndUnits / 10
                let unitDigit = tensAndUnits % 10
                
                result += tens[tensDigit]
                
                if unitDigit > 0 {
                    if unitDigit == 1 {
                        result += " mốt"
                    } else if unitDigit == 5 {
                        result += " lăm"
                    } else {
                        result += " " + units[unitDigit]
                    }
                }
            }
        }
        
        return result.trimmingCharacters(in: .whitespaces)
    }
    
    // Hàm chuyển đổi số tiền sang chữ
    func convertCurrency(amount: Int) -> String {
        return convert(number: amount) + " đồng"
    }
    
    // Hàm chuyển đổi số tiền sang chữ với định dạng tiêu chuẩn
    func formatCurrency(amount: Int) -> String {
        if amount >= 1000000000 {
            let billions = amount / 1000000000
            let remainder = amount % 1000000000
            
            if remainder == 0 {
                return "\(convert(number: billions)) tỷ đồng"
            } else {
                return "\(convert(number: billions)) tỷ \(convertRemainder(remainder)) đồng"
            }
        } else if amount >= 1000000 {
            let millions = amount / 1000000
            let remainder = amount % 1000000
            
            if remainder == 0 {
                return "\(convert(number: millions)) triệu đồng"
            } else {
                return "\(convert(number: millions)) triệu \(convertRemainder(remainder)) đồng"
            }
        } else if amount >= 1000 {
            let thousands = amount / 1000
            let remainder = amount % 1000
            
            if remainder == 0 {
                return "\(convert(number: thousands)) nghìn đồng"
            } else {
                return "\(convert(number: thousands)) nghìn \(convert(number: remainder)) đồng"
            }
        } else {
            return "\(convert(number: amount)) đồng"
        }
    }
    
    // Hàm xử lý phần dư
    private func convertRemainder(_ remainder: Int) -> String {
        if remainder == 0 {
            return ""
        }
        
        if remainder < 1000 {
            return convert(number: remainder)
        } else if remainder < 1000000 {
            let thousands = remainder / 1000
            let rem = remainder % 1000
            
            if rem == 0 {
                return "\(convert(number: thousands)) nghìn"
            } else {
                return "\(convert(number: thousands)) nghìn \(convert(number: rem))"
            }
        } else {
            let millions = remainder / 1000000
            let rem = remainder % 1000000
            
            if rem == 0 {
                return "\(convert(number: millions)) triệu"
            } else {
                return "\(convert(number: millions)) triệu \(convertRemainder(rem))"
            }
        }
    }
}

// Ví dụ sử dụng:
// let converter = VietnameseNumberConverter()
// let amount = 1234567
// let amountInWords = converter.formatCurrency(amount: amount)
// print(amountInWords) // "một triệu hai trăm ba mươi bốn nghìn năm trăm sáu mươi bảy đồng"
