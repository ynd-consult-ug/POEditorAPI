//
//  main.swift
//  POEditorAPI
//
//  Created by Oliver Drobnik on 05/11/2016.
//  Copyright © 2016 Cocoanetics. All rights reserved.
//

import Foundation

let sema = DispatchSemaphore(value: 0)

var token: String!
var projectID: Int!

let workingDirURL = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
let settingsFileURL = workingDirURL.appendingPathComponent("poet.json")

do
{
	let data = try Data(contentsOf: settingsFileURL)

	if let settings = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
	{
		token = settings["token"] as? String
		projectID = settings["projectID"] as? Int
	}
}
catch _
{
	
}

// get token from user if needed
if token == nil
{
	// no api token
	print("Enter POEditor API Token> ", terminator: "")
	token = readLine(strippingNewline: true)
}


let poeditor = POEditor(token: token)

if projectID == nil
{
	var availableProjects: [JSONDictionary]!
	
	poeditor.listProjects { result in
		
		switch result
		{
		case .success(let projects):
			availableProjects = projects
			
		case .failure(WebServiceError.serviceError(let message)):
			print("POEditor.com responded: \(message)")
			exit(1)
			break
			
		case .failure(WebServiceError.networkError(let error)):
			print("Network Error: \(error.localizedDescription)")
			exit(1)
			break
			
		case .failure(let error):
			print(error.localizedDescription)
			break
		}
		
		sema.signal()
	}
	
	sema.wait()
	
	if availableProjects == nil || availableProjects.count == 0
	{
		print("No projects found.")
		exit(1)
	}
	
	print("Projects Available")
	print("==================")
	
	for (index, project) in availableProjects.enumerated()
	{
		guard let projectID = project["id"] as? String,
			let projectName = project["name"] as? String else
		{
			continue
		}
		
		let indexStr = String(format: "%3d", index+1)
		print("\t" + indexStr + ".\t" + projectName)
	}
	
	print("\nSelect project to setup> ", terminator: "")
	
	if let string = readLine(strippingNewline: true),
		let number = Int(string)
	{
		let project = availableProjects[number-1]
		projectID = Int((project["id"] as! String))
	}
	else
	{
		print("No project selected, aborting.")
		exit(1)
	}
}
	
// save token and project ID

do
{
	let dict = ["token": token, "projectID": projectID] as [String : Any]
	let data = try JSONSerialization.data(withJSONObject: dict, options: [])
	try data.write(to: settingsFileURL)
}
catch let error
{
	print(error)
}

var projectLanguages: [JSONDictionary]!

poeditor.listProjectLanguages(projectID: projectID) { result in

	switch result
	{
	case .success(let languages):
		projectLanguages = languages
		
	case .failure(WebServiceError.serviceError(let message)):
		print("POEditor.com responded: \(message)")
		exit(1)
		break
		
	case .failure(WebServiceError.networkError(let error)):
		print("Network Error: \(error.localizedDescription)")
		exit(1)
		break
		
	case .failure(let error):
		print(error.localizedDescription)
		break
	}
	
	sema.signal()
}

sema.wait()

let completeLangs = projectLanguages.filter { (language) -> Bool in
	if let percent = language["percentage"] as? Int, percent == 100
	{
		return true
	}
	
	return false
}

let codes = completeLangs.map { (language) -> String in
	return language["code"] as! String
}

print(codes)

