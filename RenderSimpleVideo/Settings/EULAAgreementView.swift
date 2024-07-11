//
//  EULAAgreementView.swift
//  HostsWorld
//
//  Created by javi www on 6/21/23.
//

import SwiftUI

struct EULAAgreementView: View {
    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            Text(eulaAllText)
                .padding(.top, 44)
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
        .padding(.bottom, 16)
    }
}

struct EULAAgreementView_Previews: PreviewProvider {
    static var previews: some View {
        EULAAgreementView()
    }
}

let eulaAllText = """
End User License Agreement for Real Estate Zoom & Showcase
This End User License Agreement ("Agreement") is a legal agreement between you (either an individual or a single entity) and JRWAppDev ("Company") for the software product identified above, which includes computer software and may include associated media, printed materials, and "online" or electronic documentation ("Software").
By installing, copying, or otherwise using the Software, you agree to be bound by the terms of this Agreement. If you do not agree to the terms of this Agreement, do not install or use the Software.

GRANT OF LICENSE
The Company grants you a non-exclusive, non-transferable license to use the Software on a single device owned or operated by you.
COPYRIGHT
The Software is protected by copyright laws and international copyright treaties, as well as other intellectual property laws and treaties. The Software is licensed, not sold.
RESTRICTIONS
You may not:
a) Reverse engineer, decompile, or disassemble the Software.
b) Rent, lease, or lend the Software.
c) Transfer the Software or this license to any third party.
TERMINATION
Without prejudice to any other rights, the Company may terminate this Agreement if you fail to comply with its terms and conditions. In such event, you must destroy all copies of the Software.
DISCLAIMER OF WARRANTY
The Software is provided "AS IS" without warranty of any kind, either express or implied.
LIMITATION OF LIABILITY
In no event shall the Company be liable for any damages whatsoever arising out of the use of or inability to use this Software.

By using Real Estate Zoom & Showcase, you acknowledge that you have read this Agreement, understand it, and agree to be bound by its terms and conditions.

"""

